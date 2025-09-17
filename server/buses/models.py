from django.db import models


class Bus(models.Model):
    number_plate = models.CharField(max_length=20)
    current_location = models.CharField(max_length=255)

    def __str__(self):
        return self.number_plate
