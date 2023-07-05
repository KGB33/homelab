from dataclasses import dataclass, field


@dataclass
class TalosVM:
    hostname: str
    ip: str
    control: bool = False
    nameservers: list[str] = field(
        default_factory=lambda: ["10.0.9.53", "1.1.1.1", "1.0.0.1"]
    )


gnar = TalosVM("gnar", "10.0.9.21", control=True)
gwen = TalosVM("gwen", "10.0.9.22")
sion = TalosVM("sion", "10.0.9.23", control=True)
#shen = TalosVM("shen", "10.0.9.24")
teemo = TalosVM("teemo", "10.0.9.25", control=True)
twitch = TalosVM("twitch", "10.0.9.26")

nodes = [gnar, gwen, sion, twitch, teemo]
