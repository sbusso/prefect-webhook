import os

import uvicorn
from fastapi import FastAPI, Request
from prefect import get_client

app = FastAPI()

PREFECT_API_URL = os.environ[
    "PREFECT_API_URL"
]  # ensure the prefect api url is set in the environment


@app.post("/webhook/{flow_name}/{deployment_name}")
async def webhook(
    flow_name: str,
    deployment_name: str,
    request: Request,
):
    payload = await request.json()

    async with get_client() as client:
        deployment = await client.read_deployment_by_name(
            f"{flow_name}/{deployment_name}"
        )

        await client.create_flow_run_from_deployment(
            deployment.id, parameters=payload, tags=["webhook"]
        )

    return {}


if __name__ == "__main__":
    uvicorn.run(
        app, host="0.0.0.0", port=int(os.getenv("PORT", "8088")), log_level="info"
    )
