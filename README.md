# MedGuard QA

Healthcare Appointment & Prescription Management System (with GAN-based medical imaging),
wrapped in a **self-reporting QA pipeline** that connects Jira, Docker and Selenium.

## What's new here (the novelty)

1. **Metamorphic testing of the GAN.** A GAN has no single "correct" output, so tests check
   relations that must hold: brightness change, tiny noise or a mirror flip must not change
   the diagnosis, and the output must stay structurally similar (SSIM >= 0.90).
2. **Failures file their own Jira bugs.** Each failed test creates a Jira Bug (via REST API)
   with the use case, GAN model version + seed, Docker image tag, a screenshot or the failing
   input image, and a one-line reproduce command. A repeat failure comments on the open
   ticket instead of duplicating it.
3. **Traceability matrix + quality gate.** Every test is tagged `@pytest.mark.uc("UC#")`.
   `reports/traceability.html` shows pass/fail per use case, linked Jira tickets, and BLOCKS the
   gate if any use case fails or has no tests.
4. **Reproducible by construction.** Everything runs in Docker with the image tag and seed
   recorded in each ticket.

## Two more novel pieces

5. **Clinical-risk severity.** Ticket priority follows patient safety: a model flipping
   anomaly -> normal (missed diagnosis) is filed as Highest, normal -> anomaly (false alarm) as Medium.
6. **Replay capsule.** Every ticket gets a small zip (inputs + manifest + replay.sh) that reproduces the
   failure with one command on the exact image tag.

## Easiest way on a Mac

Double-click `run_demo.command` (healthy run) and then `demo_bad_release.command` (shows a bug being filed).

## Run it (Docker)

    docker compose up -d --build                 # app + GAN service + Selenium browser
    docker compose run --rm tests                # run the whole QA pipeline
    open reports/traceability.html

Watch the browser live at http://localhost:7900 (password: secret) while tests run.

### Demo a bad model release

    GAN_BUG=1 GAN_VERSION=1.1.0-bad IMAGE_TAG=bad-release docker compose up -d --build gan
    docker compose run --rm -e IMAGE_TAG=bad-release tests
    # -> metamorphic tests fail, gate = BLOCKED, a bug ticket appears (reports/jira_mock/ or real Jira)

## Jira

Without credentials, tickets are written to `reports/jira_mock/` (same payload as the real API).
For real Jira Cloud: create a free site + a project (key e.g. MG), create an API token, then

    cp .env.example .env   # fill in values
    set -a; . ./.env; set +a
    python tools/setup_jira.py     # creates UC1-UC10 epics, prints JIRA_EPIC_MAP -> paste into .env
    docker compose run --rm tests

## Run without Docker (quick local dev)

    pip install -r requirements.txt
    python gan_service/main.py &
    (cd app && TESTING_ENDPOINTS=1 python main.py) &
    pytest            # needs Chrome + a matching chromedriver

## Layout

    app/            Flask web app (UC1-UC10)
    gan_service/    GAN inference service (stand-in model; GAN_BUG=1 injects a regression)
    tests/          Selenium functional tests + GAN metamorphic tests
    tools/          jira_reporter.py (pytest plugin), setup_jira.py
    sample_output/  Example reports from a healthy run and a bad-release run

Note for Mac users: macOS AirPlay Receiver uses port 5000, so the app is exposed on
http://localhost:5050 (inside Docker it is still app:5000).

Note: the compose service is reachable from the test browser as `webapp`, not `app`, because
`.app` is a real top-level domain that Chrome force-upgrades to https (HSTS), which made the
browser fail to load http://app:5000.
