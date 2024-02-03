from fastapi import APIRouter

router = APIRouter()


@router.get("/test")  # /users/test
async def test():
    return {"message": "Hello World"}
