import os

import lambda_welcome

os.environ["CLIENT_ID"] = "client_id"
os.environ["GITHUB_URL"] = "https://github.com"


def test_handler():
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
          <a href="https://github.com/login/oauth/authorize?scope=public_repo&client_id=client_id">
          Click here</a> to begin!</a>
        </p>
      </body>
    </html>
    '''
    expected = {
        "statusCode": "200",
        "body": html_body,
        "headers": {
            "Content-Type": "text/html",
        },
    }

    assert lambda_welcome.lambda_handler(None, None) == expected
