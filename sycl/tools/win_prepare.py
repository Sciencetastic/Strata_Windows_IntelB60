"""Windows: download and prepare a Qwen3.8-Flash-Next model for the SYCL (Intel Arc) engine, with setup.py's own steps.

setup.py's Intel path (sycl/setup_intel.py) is Linux-only: it finds the Arc in sysfs and runs the engine in Docker. This
script runs only the model part of setup.py - step 5 (the GGUF shards, resumable, checked) and step 6 (tools/iq_pack.py's
native pack and tokenizer, the MTP draft layer) - and prints the paths the engine takes.

    .venv\\Scripts\\python sycl\\tools\\win_prepare.py [--model IQ2_XS] [--family qwen] [--data DIR] [--mtp on|off]
"""
import argparse
import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
import setup as S  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--family", default="qwen")
    ap.add_argument("--model", default="IQ2_XS")
    ap.add_argument("--data", default=str(ROOT.parent / "Strata-data"))
    ap.add_argument("--mtp", choices=("on", "off"), default="on")
    ap.add_argument("--draft-vocab", default="cjk")
    a = ap.parse_args()

    fam = S.FAMILIES[a.family]
    model = a.model
    data = Path(a.data)
    tag = fam["tag"] + model
    models_dir = data / "models" / tag
    models_dir.mkdir(parents=True, exist_ok=True)
    shards = [models_dir / S.model_file(fam, model, i) for i in range(1, S.model_shards(fam, model) + 1)]

    S.step(5, f"downloading {fam['title']} {model} into {models_dir}")
    for s in shards:
        if s.exists() and S.done(s):
            S.ok(f"{s.name} already downloaded")
            continue
        S.download(fam["hf"].format(q=model) + s.name, s)
    S.check_shards(shards)
    for s in shards:
        if s.name in fam.get("sha256", {}):
            S.verify_sha256(s, *fam["sha256"][s.name])
    S.ok("model files present")

    S.step(6, "preparing the model for Strata")
    llama = next((p for p in (ROOT / "build-sycl-aot" / "_deps" / "strata_llamacpp-src",
                              ROOT / "build-sycl-jit" / "_deps" / "strata_llamacpp-src") if (p / "gguf-py").is_dir()), None)
    if llama is None:
        S.fail("no llama.cpp checkout with gguf-py (build the engine first: sycl\\tools\\win-build.bat)")
    env = dict(os.environ, STRATA_GGUF_PY=str(llama / "gguf-py"))
    pack = data / "packs" / tag.lower()
    if not (pack / "native_experts.txt").exists() or not (pack / "tokenizer" / "vocab.json").exists():
        S.run([sys.executable, str(ROOT / "tools" / "iq_pack.py"), "--gguf", str(shards[0]), "--out", str(pack),
               *fam.get("pack_args", [])], env=env)
    S.ok(f"model prepared: {pack}")

    mtp = data / "mtp"
    rt = mtp / "rt"
    if a.mtp == "on" and not (rt / "experts.bin").exists():
        S.fetch_mtp(mtp, env)
        S.run([sys.executable, str(ROOT / "tools" / "mtp_pack.py"), "--src", str(mtp), "--experts", "q2_0",
               "--out", str(mtp / "mtp-q2_0.gguf")], env=env)
        S.run([sys.executable, str(ROOT / "tools" / "mtp_rt.py"), "--gguf", str(mtp / "mtp-q2_0.gguf"), "--out", str(rt)],
              env=env)
    if (rt / "experts.bin").exists():
        S.refresh_draft_vocab(rt, a.draft_vocab)
        S.ok(f"MTP draft layer: {rt}")

    sys.path.insert(0, str(ROOT / "tools"))
    from gguf_reader import GGUFFile
    ple = next((s for s in shards if any(t.name == "per_layer_token_embd.weight" for t in GGUFFile(s).tensors)), None)
    out = {"pack": str(pack), "native": str(shards[0]), "ple_gguf": str(ple) if ple else None,
           "mtp": str(rt) if (rt / "experts.bin").exists() else None}
    (data / f"win-prepared-{tag.lower()}.json").write_text(json.dumps(out, indent=1), encoding="utf-8")
    print(json.dumps(out, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
