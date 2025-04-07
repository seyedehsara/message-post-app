import requests

response = requests.post("http://127.0.0.1:8080/posts", json={
    "author": "Sara",
    "subject": "Test post",
    "body": "This is my first message"
})

print(response.status_code)
print(response.json())
