from rest_framework.views import APIView
from rest_framework.response import Response


class BusMinderListView(APIView):
    def get(self, request):
        return Response({"message": "List of bus minders"})
