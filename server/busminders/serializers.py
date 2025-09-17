from rest_framework import serializers


class BusMinderSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100)
    phone_number = serializers.CharField(max_length=15)
    email = serializers.EmailField()
