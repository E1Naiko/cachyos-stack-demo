import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST


@csrf_exempt
@require_POST
def login(request):
    try:
        data = json.loads(request.body)

        username = data.get("username", "")
        password = data.get("password", "")

        # Credenciales ficticias para realizar la prueba
        if username == "admin" and password == "1234":
            return JsonResponse({
                "success": True,
                "message": "¡Login exitoso!",
                "username": username
            })

        return JsonResponse({
            "success": False,
            "message": "Usuario o contraseña incorrectos"
        }, status=401)

    except (json.JSONDecodeError, AttributeError):
        return JsonResponse({
            "success": False,
            "message": "Solicitud inválida"
        }, status=400)
