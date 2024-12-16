# Android / UnifiedPush

Push notifications are available on Android via the UnifiedPush protocol. You can read more about it [here](https://unifiedpush.org/).

### Terms

* **Thunder server**: This is the server which polls Lemmy for new inbox messages. It must store your API key to make requests on your behalf, so it is highly recommend to self-host this service. Otherwise, you can use the one hosted by Thunder at https://thunderapp.dev.
* **UnifiedPush server**: This server acts as a gateway between the Thunder server and the UnifiedPush app on your phone. While this server can't see your API key, it can see your notifications, so you may wish to self-host this as well. Otherwise you can use the server hosted by Thunder at https://ntfy.thunderapp.dev or the default instance at https://ntfy.sh.

### Getting Started

If you do not wish to self-host anything, you can simply enable push notifications in Settings > General > Enable Inbox Notifications > Use UnifiedPush Notifications. Restart Thunder, and you should be good to go!

### Self-Hosting Thunder Server

If you want, you can self-host the Thunder server, which is available [here](https://github.com/thunder-app/thunder_server), in one of the following ways.

#### Docker Run

> TODO: Add `docker run` command for Postgres.

``` bash
docker run -d \
    --name thunder-server \
    -p 5100:5100 \
    --restart=unless-stopped \
    ghcr.io/thunder-app/thunder_server
```

#### Docker-Compose

Download [this docker-compose file](https://github.com/thunder-app/thunder_server/blob/main/docker-compose.yml), then run `docker-compose up -d` in the same directory as the file.

#### Certificates

Note that you may wish to run the Thunder server being an Nginx reverse proxy which is configured to obtain signed certificates. However, that is beyond the scope of this document.

> TODO: Add a sample nginx.conf; add nginx to docker run/compose.

### Self-Hosting UnifiedPush Server

If you want, you can self-host the UnifiedPush server. For this, we recommend [ntfy](https://github.com/binwiederhier/ntfy), and you can follow their self-hosting instructions [here](https://docs.ntfy.sh/install/).

Note that if you set `auth-default-access` to `deny-all`, which is recommended, you will have to grant write access for UnifiedPush topics with `ntfy access '*' 'up*' write-only`. See [this page](https://docs.ntfy.sh/config/#access-control) for more info.

Finally, when you install the ntfy Android app ([Google Play](https://play.google.com/store/apps/details?id=io.heckel.ntfy), [F-Droid](https://f-droid.org/packages/io.heckel.ntfy/)), be sure to navigate to Settings > Default server and enter your custom URL. If you have set up user access, navigate to Manage users and enter your credentials there. Be sure to do this before you enable UnifiedPush notifications in Thunder.

| ![](https://github.com/thunder-app/thunder/assets/7417301/4535cfde-1844-46d0-ba50-8baf4bf69b91) |
| - |