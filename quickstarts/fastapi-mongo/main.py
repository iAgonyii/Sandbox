import os
import uvicorn

from dotenv import load_dotenv
from fastapi import FastAPI
from starlette.middleware.cors import CORSMiddleware
from starlette.middleware.httpsredirect import HTTPSRedirectMiddleware

from api import admin, users

load_dotenv()

app = FastAPI(
    docs_url=None if os.getenv('ENV') == 'prod' else "/docs",
    redoc_url=None if os.getenv('ENV') == 'prod' else "/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# if os.getenv('ENV') == 'prod':
#     app.add_middleware(HTTPSRedirectMiddleware)

app.include_router(admin.router, prefix="/admin", tags=["Admin"])
app.include_router(users.router, prefix="/users", tags=["Users"])


@app.get("/")
async def root():
    return {"message": "Test"}


if __name__ == "__main__":
    if os.getenv('ENV') == 'prod':
        uvicorn.run("main:app", port=7575, host='0.0.0.0', reload=True, server_header=False)
    else:
        uvicorn.run("main:app", port=7575, host='127.0.0.1', reload=True, server_header=False)
