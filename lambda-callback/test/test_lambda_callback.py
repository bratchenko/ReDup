import os

import pytest
import requests_mock

import lambda_callback

os.environ["CLIENT_ID"] = "client_id"
os.environ["CLIENT_SECRET"] = "client_secret"
os.environ["GITHUB_URL"] = "https://github.com"
os.environ["GITHUB_API_URL"] = "https://api.github.com"
os.environ["GITHUB_TEMPLATE_REPO_OWNER_NAME"] = "owner_name"
os.environ["GITHUB_TEMPLATE_REPO_NAME"] = "template_repo"
os.environ["GITHUB_DUPLICATE_REPO_NAME"] = "Dup repo"
os.environ["GITHUB_DUPLICATE_REPO_DESCRIPTION"] = "Duplicate repo description"


@pytest.fixture()
def url_mock():
    with requests_mock.Mocker() as m:
        yield m


def test_handler_success(url_mock):
    expected = {
        "statusCode": "200",
        "body": "We have successfully copied our repository to your account! Enjoy!",
        "headers": {
            "Content-Type": "application/json",
        },
    }
    url_mock.register_uri("POST", "https://github.com/login/oauth/access_token",
                          status_code=200,
                          json={"access_token": "token1"})
    url_mock.register_uri("POST", "https://api.github.com/repos/owner_name/template_repo/generate?access_token=token1",
                          status_code=201,
                          json={"message": "Created"})
    event = {"queryStringParameters": {"code": 10}}
    actual = lambda_callback.lambda_handler(event, None)
    assert actual == expected


def test_handler_code_error():
    expected = {
        "statusCode": "400",
        "body": "No code provided to obtain GitHub oauth token.",
        "headers": {
            "Content-Type": "application/json",
        },
    }
    event = {"queryStringParameters": {"code": 0}}
    actual = lambda_callback.lambda_handler(event, None)
    assert actual == expected


def test_get_user_access_token_success(url_mock):
    expected = "token1"
    url_mock.register_uri("POST", "https://github.com/login/oauth/access_token",
                          status_code=200,
                          json={"access_token": "token1"})
    actual = lambda_callback.get_user_access_token("10")
    assert actual == expected


def test_get_user_access_token_fail(url_mock):
    url_mock.register_uri("POST", "https://github.com/login/oauth/access_token",
                          status_code=200,
                          json={"error": "token_test_error", "error_description": "Test error"})

    with pytest.raises(lambda_callback.AccessTokenError) as exc_info:
        lambda_callback.get_user_access_token("10")
    assert exc_info.value.code == 400
    assert exc_info.value.message == "GitHub response error: Test error"


def test_create_repo_success(url_mock):
    expected_method = "POST"
    expected_url = "https://api.github.com/repos/owner_name/template_repo/generate?access_token=token1"
    expected_repo_name = "Dup repo"
    expected_repo_description = "Duplicate repo description"

    url_mock.register_uri("POST", "https://api.github.com/repos/owner_name/template_repo/generate?access_token=token1",
                          status_code=201,
                          json={"message": "Created"})
    lambda_callback.create_repo("token1")
    assert url_mock.called
    assert url_mock.request_history[0].method == expected_method
    assert url_mock.request_history[0].url == expected_url
    assert url_mock.request_history[0].json()["name"] == expected_repo_name
    assert url_mock.request_history[0].json()["description"] == expected_repo_description


def test_create_repo_fail_duplicate(url_mock):
    url_mock.register_uri("POST", "https://api.github.com/repos/owner_name/template_repo/generate?access_token=token1",
                          status_code=422,
                          json={"error": "repo_test_error"})

    with pytest.raises(lambda_callback.DuplicateRepositoryError) as exc_info:
        lambda_callback.create_repo("token1")
    assert exc_info.value.code == 422
    assert exc_info.value.message == "We have likely already created a repository for you," \
                                     " as the repository with our name already exists on your profile. Check it out."
