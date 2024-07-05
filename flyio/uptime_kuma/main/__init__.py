from __future__ import annotations

from dataclasses import dataclass, field
import json
import os

import dagger
from dagger import dag, function, object_type
from pulumi import automation as pa

DOMAIN = "uptime.kgb33.dev"


@object_type
class UptimeKuma:
    pulumi_access_token: dagger.Secret
    cloudflare_token: dagger.Secret
    fly_api_token: dagger.Secret
    fly_toml: dagger.File
    flyio: dagger.Flyio = field(init=False)

    def __post_init__(self):
        self.flyio = dag.flyio(fly_api_token=self.fly_api_token, fly_toml=self.fly_toml)
        # Set secrets in the runtime container for Pulumi

    async def _set_env(self):
        os.environ["PULUMI_ACCESS_TOKEN"] = await self.pulumi_access_token.plaintext()
        os.environ["CLOUDFLARE_API_TOKEN"] = await self.cloudflare_token.plaintext()

    @function
    async def up(self) -> str:
        await self._set_env()
        print(await self.flyio.deploy())
        cert_info: dict[str, str] = json.loads(await self.flyio.cert_add(DOMAIN))
        ip_info: list[dict[str, str]] = json.loads(await self.flyio.ip_list())
        stack = pulumi_cf_stack(ip_info, cert_info)
        up_res = stack.up(on_output=print)
        return json.dumps(up_res.summary.resource_changes, indent=4)

    @function
    async def down(self) -> str:
        # TODO: remove fly deployment
        await self._set_env()
        cert_info: dict[str, str] = json.loads(await self.flyio.cert_add(DOMAIN))
        ip_info: list[dict[str, str]] = json.loads(await self.flyio.ip_list())
        stack = pulumi_cf_stack(ip_info, cert_info)
        res = stack.destroy(on_output=print)
        return json.dumps(res.summary.resource_changes, indent=4)


def pulumi_cf_stack(ips: list[dict[str, str]], certs: dict[str, str]) -> pa.Stack:
    def _program():
        import pulumi
        import pulumi_cloudflare as cf

        config = pulumi.Config()
        zone_id = config.get("zoneId", "33f1d2b5c5cc2302c6487142d00cfc8f")

        # Validation Record
        cf.Record(
            f"{DOMAIN}-validator",
            zone_id=zone_id,
            name=certs["DNSValidationHostname"],
            type="CNAME",
            value=certs["DNSValidationTarget"],
        )

        # A/AAAA Records
        for ip in ips:
            record_type = "AAAA" if ip["Type"] == "v6" else "A"
            cf.Record(
                f"{DOMAIN}-{record_type}",
                zone_id=zone_id,
                name=DOMAIN,
                type=record_type,
                value=ip["Address"],
            )

    stack = pa.create_or_select_stack(
        stack_name="dev", project_name="uptime_kuma_fly", program=_program
    )
    stack.workspace.install_plugin("cloudflare", "v5.31.0")
    return stack


@dataclass
class FlyCert:
    Configured: bool
    DNSValidationHostname: str
    DNSValidationTarget: str


@dataclass
class FlyIP:
    Address: str
    Type: str
