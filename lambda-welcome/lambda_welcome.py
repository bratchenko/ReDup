import os


def lambda_handler(event, context):
    client_id = os.environ["CLIENT_ID"]
    github_url = os.environ["GITHUB_URL"]

    html_body = f'''
    <html>
      <head>
      </head>
      <body>
        <p>
          Well, hello there!
        </p>
        <p>
          We're going to copy this application's repository to your account! Isn't that exciting? <br>
          For that we will need to access your public repositories from our GitHub application. <br>
          <a href="{github_url}/login/oauth/authorize?scope=public_repo&client_id={client_id}">
          Click here</a> to begin!</a>
        </p>
      </body>
    </html>
    '''

    return {
        "statusCode": "200",
        "body": html_body,
        "headers": {
            "Content-Type": "text/html",
        },
    }
