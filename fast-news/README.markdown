task queue tasks should be handled by the `tasks` module (see dispatch.py).
deploy `tasks` separately by changing the value for `module` in `app.yaml` and removing the minimum autoscaling, then deploy.
