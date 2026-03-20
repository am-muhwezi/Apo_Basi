from rest_framework.throttling import AnonRateThrottle, UserRateThrottle


class LoginRateThrottle(AnonRateThrottle):
    scope = 'login'


class RegistrationRateThrottle(AnonRateThrottle):
    scope = 'registration'


class TokenRefreshRateThrottle(AnonRateThrottle):
    scope = 'token_refresh'


class ContactFormThrottle(AnonRateThrottle):
    scope = 'contact_form'


class AuthenticatedUserThrottle(UserRateThrottle):
    scope = 'authenticated_user'
