from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model
import threading
from django.core.mail import send_mail
from django.conf import settings as django_settings
from rest_framework.decorators import throttle_classes
from .throttles import LoginRateThrottle, RegistrationRateThrottle, ContactFormThrottle
from .serializers import (
    UserRegistrationSerializer,
    UserSerializer,
    PasswordChangeSerializer,
    ProfileUpdateSerializer
)

User = get_user_model()


class UserRegistrationView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserRegistrationSerializer
    permission_classes = [AllowAny]
    throttle_classes = [RegistrationRateThrottle]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Generate JWT tokens for the user
        refresh = RefreshToken.for_user(user)

        return Response({
            'user': UserSerializer(user).data,
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            },
            'message': 'User registered successfully'
        }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([LoginRateThrottle])
def login_view(request):
    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response({
            'error': 'Username/Email/Phone and password are required'
        }, status=status.HTTP_400_BAD_REQUEST)

    # Try to authenticate with username first
    user = authenticate(username=username, password=password)

    # If authentication failed, try with email
    if user is None:
        try:
            user_by_email = User.objects.get(email=username)
            user = authenticate(username=user_by_email.username, password=password)
        except User.DoesNotExist:
            pass

    # If still None, try with phone number
    if user is None:
        try:
            user_by_phone = User.objects.get(phone_number=username)
            user = authenticate(username=user_by_phone.username, password=password)
        except (User.DoesNotExist, AttributeError):
            pass

    if user is not None:
        # Update last_login timestamp
        from django.utils import timezone
        user.last_login = timezone.now()
        user.save(update_fields=['last_login'])

        refresh = RefreshToken.for_user(user)
        return Response({
            'user': UserSerializer(user).data,
            'tokens': {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            },
            'message': 'Login successful'
        }, status=status.HTTP_200_OK)
    else:
        return Response({
            'error': 'Invalid credentials'
        }, status=status.HTTP_401_UNAUTHORIZED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    try:
        refresh_token = request.data.get('refresh_token')
        if refresh_token:
            token = RefreshToken(refresh_token)
            token.blacklist()
        return Response({
            'message': 'Logout successful'
        }, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({
            'error': 'Invalid token'
        }, status=status.HTTP_400_BAD_REQUEST)


class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user

    def update(self, request, *args, **kwargs):
        serializer = ProfileUpdateSerializer(
            self.get_object(),
            data=request.data,
            partial=True
        )
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        return Response({
            'user': UserSerializer(user).data,
            'message': 'Profile updated successfully'
        }, status=status.HTTP_200_OK)


class ChangePasswordView(generics.UpdateAPIView):
    serializer_class = PasswordChangeSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user

    def update(self, request, *args, **kwargs):
        user = self.get_object()
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        if not user.check_password(serializer.data.get('old_password')):
            return Response({
                'error': 'Wrong password'
            }, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(serializer.data.get('new_password'))
        user.save()

        return Response({
            'message': 'Password changed successfully'
        }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_profile(request):
    """
    Get the current user's profile information
    """
    user = request.user
    profile_data = UserSerializer(user).data

    # Add additional profile data based on user type
    if hasattr(user, 'parent'):
        profile_data['profile_type'] = 'parent'
    elif hasattr(user, 'busminder'):
        profile_data['profile_type'] = 'busminder'
    else:
        profile_data['profile_type'] = 'admin'

    return Response({
        'user': profile_data
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])  # Secured: requires authentication
def list_users(request):
    """
    List all users - for admin/testing purposes
    """
    users = User.objects.all()
    return Response(UserSerializer(users, many=True).data, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def health_check(request):
    """
    Simple health check endpoint
    """
    return Response({'status': 'ok', 'message': 'Server is running'}, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([ContactFormThrottle])
def contact_form(request):
    """
    POST /api/contact/
    Accepts a contact form submission and emails it to the support inbox.
    Rate limited to 5 submissions per hour per IP.
    """
    name = (request.data.get('name') or '').strip()
    email = (request.data.get('email') or '').strip()
    school = (request.data.get('school') or '').strip()
    message = (request.data.get('message') or '').strip()

    if not name or not email or not message:
        return Response({'error': 'Name, email, and message are required.'}, status=status.HTTP_400_BAD_REQUEST)

    subject = f"ApoBasi Contact: {name}" + (f" ({school})" if school else "")
    body = f"From: {name} <{email}>\n"
    if school:
        body += f"School: {school}\n"
    body += f"\n{message}"

    recipient = getattr(django_settings, 'CONTACT_EMAIL', 'hello@apobasi.com')
    from_email = django_settings.DEFAULT_FROM_EMAIL

    def _send():
        send_mail(subject=subject, message=body, from_email=from_email,
                  recipient_list=[recipient], fail_silently=True)

    threading.Thread(target=_send, daemon=True).start()

    return Response({'success': True}, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([AllowAny])
def school_info(request):
    """
    GET /api/school/info/
    Returns school configuration for this deployment.
    Unauthenticated so the Flutter app can call it before login if needed.
    """
    lat = getattr(django_settings, 'SCHOOL_LATITUDE', None)
    lng = getattr(django_settings, 'SCHOOL_LONGITUDE', None)

    return Response({
        'schoolLatitude': lat,
        'schoolLongitude': lng,
        'configured': lat is not None and lng is not None,
    }, status=status.HTTP_200_OK)
