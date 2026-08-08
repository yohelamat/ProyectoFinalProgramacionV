import json

def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "¡Hola desde AWS Lambda! Lógica de negocio activa y orquestada por Terraform."
        })
    }