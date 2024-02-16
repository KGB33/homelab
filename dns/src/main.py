from typing import Self
import dagger
from dagger import dag, function, object_type, field


@object_type
class PowerDNS:
    # Foo
    cfg: dagger.Directory = field()

    @classmethod
    async def create(cls, cfg: dagger.Directory | None = None) -> Self:
        if cfg is None:
            cfg = await dag.current_module().source().directory("cfg")
        return cls(cfg=cfg)

    @function
    def cli(self) -> dagger.Terminal:
        return (
            dag.container()
            .from_("alpine")
            .with_exec(["apk", "add", "drill", "nmap"])
            .with_service_binding("resolver", self.base_resolver().as_service())
            .terminal()
        )

    @function
    def base_resolver(self) -> dagger.Container:
        return (
            dag.container()
            .from_("powerdns/pdns-recursor-master")
            .with_file("/etc/powerdns/recursor.yml", self.cfg.file("recursor.yaml"))
            .with_exposed_port(5353, protocol=dagger.NetworkProtocol.TCP)
            # .with_exposed_port(5353, protocol=dagger.NetworkProtocol.UDP)
            .with_service_binding("auth", self.base_auth().as_service())
        )

    @function
    def base_auth(self) -> dagger.Container:
        return (
            dag.container()
            .from_("powerdns/pdns-auth-master")
            .with_file("/etc/powerdns/pdns.conf", self.cfg.file("pdns.conf"))
            .with_exposed_port(5353, protocol=dagger.NetworkProtocol.TCP)
            # .with_exposed_port(5353, protocol=dagger.NetworkProtocol.UDP)
        )

    @function
    def base_dnsdist(self) -> dagger.Container:
        return dag.container().from_("")
