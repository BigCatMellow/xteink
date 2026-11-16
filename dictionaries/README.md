# English Wiktionary for XTEINK

This builds **English Wiktionary**, not GCIDE or Webster's 1913, as an
SD-card-ready offline StarDict dictionary. The source is the Wiktionary mirror
in [itsthisjustin/sd-plugins](https://github.com/itsthisjustin/sd-plugins/releases/tag/dictionaries),
originally derived from [kaikki.org](https://kaikki.org/dictionary/English/).

## Get the package

Open **Actions → Build English Wiktionary for XTEINK → latest successful run**,
then download the **wiktionary-en-xteink** workflow artifact. Extract the
artifact ZIP to find `wiktionary-en-xteink.zip`.

The build ZIP has this exact SD-card layout:

```text
dictionaries/
  wiktionary-en/
    english.ifo
    english.idx
    english.dict
    ATTRIBUTION.txt
```

Extract **wiktionary-en-xteink.zip to the SD-card root** (not into `Apps/`,
`XTApps/` or an additional `dictionaries/` folder). The `.idx` and
`.dict` are deliberately uncompressed. Keep your previous dictionary until
this one has been tested on the device.

For **stock XTOS Licorice**: open Settings → Reading options → Dictionary
lookup → Import guide; follow the installed firmware's instructions for
selecting/importing the StarDict files. The workflow provides loose StarDict
files, not the converted text shards used by a *separate* Dictionary mini-app.
Do not install this ZIP to `XTApps/dict/files/`.

For **CrossPoint-based readers**: choose Wiktionary English under the reader's
dictionary settings, using the firmware's own instructions.

## Build / verify

Use Python 3 (no third-party packages). Download `english.ifo`, `english.idx`
and `english.dict.dz` from the [dictionary release](https://github.com/itsthisjustin/sd-plugins/releases/tag/dictionaries)
into a single local directory (the workflow does this for you), then:

```sh
python3 dictionaries/build_wiktionary.py --source /path/to/downloads --output dist/wiktionary-en-xteink.zip
python3 -m unittest discover -s dictionaries -p 'test_*.py' -v
```

The build verifies the **pinned 2026-11-01 SHA-256 hashes**, reads all 32-bit
StarDict index entries, checks headword offsets and lengths against the
uncompressed definition data, checks IFO metadata, and verifies the ZIP. It
fails closed if the rolling upstream assets are replaced with another version.
Update the three pins only after inspecting/verifying the new matching set.

**Limitations:** Source-format and host tests do not prove stock Licorice can
import or search this many words. No physical device test or SD-card edit has
been performed. The source dictionary's quality, definitions and inflections
are preserved; this conversion does not add new entries or synonyms.

## License / credit

Wiktionary entries are contributed by the English Wiktionary community and
available under CC BY-SA and GFDL. See the included `ATTRIBUTION.txt`, source
repository's licensing, and [Wiktionary copyrights](https://en.wiktionary.org/wiki/Wiktionary:Copyrights).
