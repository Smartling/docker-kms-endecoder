Work is in progress.

```
docker build .
docker run -e AWS_KMS_KEY_ID="189d219f-0000-0000-0000-00000000" -e INPUT_TEXT_BASE64="sometext" -e ACTION="encrypt" <docker image id>
docker run -e INPUT_TEXT_BASE64="$(cat /tmp/encrypted)" -e ACTION="decrypt" endecoder <docker image id>
```
