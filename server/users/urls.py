from django.urls import path
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from . import views

app_name = 'users'

urlpatterns = [
    # Authentication endpoints
    path('register/', views.UserRegistrationView.as_view(), name='register'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),

    # JWT token endpoints
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Profile management
    path('profile/', views.ProfileView.as_view(), name='profile'),
    path('profile/detail/', views.user_profile, name='profile_detail'),
    path('change-password/', views.ChangePasswordView.as_view(), name='change_password'),

    # List users
    path('', views.list_users, name='list_users'),

    # Health check
    path('health/', views.health_check, name='health_check'),
]