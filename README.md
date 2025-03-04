# certbot-dns-aliyun

> 解决阿里云 DNS 不能自动为通配符证书续期的问题

## 原理

当我们使用 certbot 申请**通配符**证书时，需要手动添加 TXT 记录。每个 certbot 申请的证书有效期为 3 个月，虽然 certbot 提供了自动续期命令，但是当我们把自动续期命令配置为定时任务时，我们无法手动添加新的 TXT 记录用于 certbot 验证。

好在 certbot 提供了一个 hook，可以编写一个 Shell 脚本。在续期的时候让脚本调用 DNS 服务商的 API 接口动态添加 TXT 记录，验证完成后再删除此记录。

## 安装(CommandLine)

1. 安装 aliyun cli 工具

   ```shell
   wget https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz
   tar xzvf aliyun-cli-linux-latest-amd64.tgz
   sudo cp aliyun /usr/local/bin
   rm aliyun
   ```

   安装完成后需要配置[凭证信息](https://help.aliyun.com/document_detail/110341.html)

2. 安装 certbot-dns-aliyun 插件

   ```shell
   wget https://cdn.jsdelivr.net/gh/justjavac/certbot-dns-aliyun@main/alidns.sh
   sudo cp alidns.sh /usr/local/bin
   sudo chmod +x /usr/local/bin/alidns.sh
   sudo ln -s /usr/local/bin/alidns.sh /usr/local/bin/alidns
   rm alidns.sh
   ```

3. 申请证书

   测试是否能正确申请：

   ```sh
   certbot certonly -d *.example.com --manual --preferred-challenges dns --manual-auth-hook "alidns" --manual-cleanup-hook "alidns clean" --dry-run
   ```

   正式申请时去掉 `--dry-run` 参数：

   ```sh
   certbot certonly -d *.example.com --manual --preferred-challenges dns --manual-auth-hook "alidns" --manual-cleanup-hook "alidns clean"
   ```

4. 证书续期

   ```sh
   certbot renew --manual --preferred-challenges dns --manual-auth-hook "alidns" --manual-cleanup-hook "alidns clean" --dry-run
   ```

   如果以上命令没有错误，把 `--dry-run` 参数去掉。

5. 自动续期

   添加定时任务 crontab。

   ```sh
   crontab -e
   ```

   输入

   ```txt
   1 1 */1 * * root certbot renew --manual --preferred-challenges dns --manual-auth-hook "alidns" --manual-cleanup-hook "alidns clean" --deploy-hook "nginx -s reload"
   ```

   上面脚本中的 `--deploy-hook "nginx -s reload"` 表示在续期成功后自动重启 nginx。
   
## 安装（Dockerfile）

   下载 Dockerfile 以及 entrypoint.sh, 确保他们在同一文件夹下。目前 Dockerfile 中默认下载 amd64 版本，其他架构请修改对应的 Aliyun CLI URL。
   
1. 创建 Image
   
   进入 Dockerfile 同目录:
   ```sh
   docker build -t certbot-alicli .
   ```

   使用代理（可选）:
   ```sh
   docker build . \
    --build-arg "HTTP_PROXY=http://127.0.0.1:7890" \
    --build-arg "HTTPS_PROXY=http://127.0.0.1:7890" \
    -t certbot-alicli
   ```
3. 运行容器
   ```sh
   docker run \
   -e REGION=YOUR_REGEION \
   -e ACCESS_KEY_ID=YOUR_ACCESS_KEY \
   -e ACCESS_KEY_SECRET=YOUR_ACCESS_SECRET \
   -e DOMAIN=YOUR_DOMAIN \
   -e EMAIL=YOUR_NOTIFICATION_EMAIL \   // 证书刷新通知邮箱
   -e CRON_SCHEDULE="0 0 * * *" \   // 自定义证书刷新间隔
   -v /path/letsencrypt:/etc/letsencrypt \ // 将容器内的证书路径完整映射到宿主机
   -d certbot-alicli
   ```
