def test_health_check():
    from tests.conftest import client

    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "OK"}
