import requests

post_id = "g8edyWIyy9i0HnMUsVcy"  

response = requests.put(f"https://crystalloids-candidates.ew.r.appspot.com/posts/{post_id}", json={
    "subject": " Updated Subject!",
    "body": "This post was updated using the live PUT API!"
})

print(response.status_code)
print(response.json())
