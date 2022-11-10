# certbot-dns-aliyun

> 解决阿里云 DNS 不能自动为通配符证书续期的问题

## 原理

当我们使用 certbot 申请**通配符**证书时，需要手动添加 TXT 记录。每个 certbot 申请的证书有效期为 3 个月，虽然 certbot 提供了自动续期命令，但是当我们把自动续期命令配置为定时任务时，我们无法手动添加新的 TXT 记录用于 certbot 验证。

好在 certbot 提供了一个 hook，可以编写一个 Shell 脚本。在续期的时候让脚本调用 DNS 服务商的 API 接口动态添加 TXT 记录，验证完成后再删除此记录。

## 安装

1. 安装 aliyun cli 工具

   ```shell
   wget https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz
   tar xzvf aliyun-cli-linux-latest-amd64.tgz
   sudo cp aliyun /usr/local/bin
   ```

   安装完成后需要配置[凭证信息](https://help.aliyun.com/document_detail/110341.html)

2. 安装 certbot-dns-aliyun 插件

   ```shell
   wget https://cdn.jsdelivr.net/gh/justjavac/certbot-dns-aliyun/alidns.sh
   sudo cp alidns.sh /usr/local/bin
   sudo chmod +x /usr/local/bin/alidns.sh
   sudo ln -s /usr/local/bin/alidns.sh /usr/local/bin/alidns
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
