    # proxy to VRE instance is root - do not proxy aliases configured before
    ProxyPass /virtualfolder/ !
    ProxyPass /repository/ !
    ProxyPass /webdav/ !
    ProxyPass /scipion/ !
    ProxyPass / http://127.0.0.1:8004/
    ProxyPassReverse / http://127.0.0.1:8004

    

