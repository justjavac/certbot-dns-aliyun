# certbot-dns-aliyun

> 解决阿里云 DNS 不能自动为通配符证书续期的问题

## 原理

当我们使用 certbot 申请通配符证书时，我们需要手动添加 TXT 记录。每个 certbot 申请的证书有效期为 3 个月，虽然 certbot 提供了贴心的自动续期命令，但是当我们把自己续期命令配置为定时任务时，我们无法手动添加 TXT 记录。

好在 certbot 提供了一个 hook，可以编写一个 Shell 脚本，让脚本调用 DNS 服务商的 API 接口，动态添加 TXT 记录。
