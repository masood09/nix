# Generated from the minecraft.org server-side mod list.
# Mirrors the nix-minecraft symlinks.mods/linkFarmFromDrvs pattern for minecraft2.
{pkgs}: {
  # Amendments 1.20-2.2.5 (required)
  amendments = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/6iTJugQR/versions/wNje5tQz/amendments-1.20-2.2.5-fabric.jar";
    sha512 = "59551bf46957fcde18231a226a614a5c357a140e18c4230e8132a24140fd27b0c95eb8228073d7ea024035b3ca195e4d6e3b06679b6731d2bac294a683cb299d";
  };

  # Architectury 9.2.14 (required)
  architectury = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/lhGA9TYQ/versions/WbL7MStR/architectury-9.2.14-fabric.jar";
    sha512 = "4cb8f009fd522d68a795d2cf5a657bdbe248b32ba7c33cd968f5ab521e9d60e198f8a3f6c50e7d960a2b8f50375116be0db1fd44b5710ea758697d8ea70d15de";
  };

  # Athena 3.1.2 (required)
  athena = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/b1ZV3DIJ/versions/mXJWSwbJ/athena-fabric-1.20.1-3.1.2.jar";
    sha512 = "e55d49348a9d944bbd19390c64a4f42a1375eaaf0cbd4d69b4f523e441d9d23ce9498c912db724260cde32a43b776832cb867161e0989995d974de7e19e12389";
  };

  # Balm 7.3.38 (required)
  balm = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/MBAkmtvl/versions/TSihd8MJ/balm-fabric-1.20.1-7.3.38.jar";
    sha512 = "fc3212781606186b881a956846d262fbe7fc068668b601749aa965b341cb20fb28e28da7591a258e4fa184d3931ef4c5e9bf7c298c8450ccd367d0be0510e8fa";
  };

  # Carry On 2.1.2.7 (required)
  carry_on = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/joEfVgkn/versions/Mkla4B3q/carryon-fabric-1.20.1-2.1.2.7.jar";
    sha512 = "ca96f56dba50ea4827ec7a15bc590ccb29aba01896550d3cb398bed18acdf469dd351cdc9312e4743f54955b3162e744c58d76c88eb79b1e5e5b4570f5b33c64";
  };

  # Create 6.0.8.1+build.1744-mc1.20.1 (required)
  create = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Xbc0uyRg/versions/HAqwA6X1/create-fabric-6.0.8.1%2Bbuild.1744-mc1.20.1.jar";
    sha512 = "6edaddb93bc87bf8204376d3ceddd3e3dfec1d716556a5925802f2ade59ce5a660ded50088fa94188842ff83fc29445363dfa5d423e425b1574092833b6fa896";
  };

  # Create Crafts & Additions 1.3.4 (required)
  createaddition = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/kU1G12Nn/versions/KIAYldwh/createaddition-fabric%2B1.20.1-1.3.4.jar";
    sha512 = "30183dc89d483feb1f84647661ca97ef9bcc917a50dc1a38d5d034d176339fae3cc92fce7d60ae73b0bdb5134b7dfe4098e4237d818bc64d304469bb0e6cff10";
  };

  # Create Slice & Dice 3.5.2-fabric (required)
  sliceanddice = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/GmjmRQ0A/versions/g0GPaHDq/sliceanddice-fabric-3.5.2.jar";
    sha512 = "080b4d8863e66e1eef7f767c2a674c3e860b5fb91abd7906301f180f6b321d60132f2b3b7089b17d75705888813a73eabac4c8a796b80938f6acda4b6f662692";
  };

  # Create: Framed 1.7.3+1.20.1 (required)
  create_framed = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/15fFZ3f4/versions/IPl2ZzII/createframed-1.7.3%2B1.20.1.jar";
    sha512 = "d95e4ec4484552fdd014d7f41c019f58e40973cc25d2a74ebdf1bfaabf875c0bcfef8ce72616352a30064ff57e38e4fd987dfa0f04d1ac07ef5a79d87727c662";
  };

  # Create: Interiors 0.6.0 (required)
  interiors = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/r4Knci2k/versions/o01QffwP/interiors-1.20.1-fabric-0.6.0.jar";
    sha512 = "dc54c24d378cec5414005e383e6112642fa00f938e47a3c508ea8090b51cabb669d08d519f0de86f24b45563f3a52c1d6022d9b9094b977b0ea713bde257202e";
  };

  # Create: New Age 1.1.7f+mc1.20.1 (required)
  create_new_age = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/FTeXqI9v/versions/ILLS3a8B/create-new-age-1.1.7f%2Bfabric-mc1.20.1.jar";
    sha512 = "4fd664d779082efe35151e066d86fe44706927086252469e1152d7099bad2ce57094b5873e3b16294c68c0a7219e1f6a980108e7a48b43365e4b27fd97826450";
  };

  # Create: Steam 'n' Rails 1.7.2+fabric-mc1.20.1 (required)
  railways = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/ZzjhlDgM/versions/PEA8dAwJ/Steam_Rails-1.7.2%2Bfabric-mc1.20.1.jar";
    sha512 = "dacd75c3461f014f2a7caae77075b36c189e38eb23d887bfbd6f6ad66b27eeb699ee72908a4c973f8abbf32f35c0110bbb37d54e71dbdccbd676bc5c781339ec";
  };

  # Create: Structures 1.1.0 (required)
  create_structures = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/IAnP4np7/versions/nqsTHZwx/create-structures-0.1.1-1.20.1-FABRIC.jar";
    sha512 = "56d693c501b655d52dc21673efe003a99feedfa44cf89afed82fae97c1d6be8fd2c8a9d0c8f126ecbe37116bf2a4631b8bb725bdc870a3382e4791c49cce04b6";
  };

  # Cristel Lib 1.1.5 (required)
  cristel_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/cl223EMc/versions/tBnivdbu/cristellib-1.1.5-fabric.jar";
    sha512 = "50ac2ac365932c5ea43a8baa67c2509292ae810fbe15848f202160c0bac3ef5ae648f175ae93436a9226e5b082cec562fab8da17c524bb642360aa859ef52652";
  };

  # Fabric API 0.92.8+1.20.1 (required)
  fabric_api = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/aLxYjsiv/fabric-api-0.92.8%2B1.20.1.jar";
    sha512 = "c1cb983e66cb09e74d318c5e9093296be56968be36626eaa603a08826e2bf0ebde7b81ec3da81580c5e6ceae22fc29b59efe2f4d5fd9933c1352f89a878c24a4";
  };

  # Fabric Language Kotlin 1.13.11+kotlin.2.3.21 (required)
  fabric_language_kotlin = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Ha28R6CL/versions/2i87JpYj/fabric-language-kotlin-1.13.11%2Bkotlin.2.3.21.jar";
    sha512 = "fa5ed2613f7216999cc0c5ddc71906f082a32b52507d7160acbdcf0eb8de12993ba302e5afde6681d025008ecc66c7533fc0c21deb672ef681b2194fb9be4245";
  };

  # FallingTree 4.3.4 (required)
  fallingtree = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Fb4jn8m6/versions/NrtzFkZE/FallingTree-1.20.1-4.3.4.jar";
    sha512 = "487cd36886cb791a3f252c90818d5c1cedeec5080a7f874b0bfafff328c8fcc9b2acee03fe40f8397355e8a2a092d2f34cb40671c786c0d9d035728c971d4e9c";
  };

  # Farmer's Delight 1.20.1-2.4.1+refabricated (required)
  farmers_delight = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/7vxePowz/versions/Z8UNayLO/FarmersDelight-1.20.1-2.4.1%2Brefabricated.jar";
    sha512 = "4fa3d8756af6df2135f19b6b78972b098e75fbfb189252288f782ad00c2a56ce6b12320e8fe8975c250f0cc001daeafb24a91bb1c09717c01302225807599450";
  };

  # Forge Config API Port 8.0.3 (required)
  forge_config_api_port = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/ohNO6lps/versions/HvR3IdRE/ForgeConfigAPIPort-v8.0.3-1.20.1-Fabric.jar";
    sha512 = "15144d6d7b74dfbe2eede6e3b0aa0c841670be1bd6121608bc28f3b1e46846ccd36b506060a081c988da96cf46fce8bf2e55601e3934b9a52d22dc2fa6cbfd32";
  };

  # Handcrafted 3.0.6 (required)
  handcrafted = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/pJmCFF0p/versions/NRw0CDAc/handcrafted-fabric-1.20.1-3.0.6.jar";
    sha512 = "92c3b47c635196d0991831ce64e2c47bd9d666ee6213bbba87b8f0214cccbba626a564ad130ec0336e94936568dce462d1ff6ca726a81134518795709632602e";
  };

  # JamLib 1.3.6+1.20.1 (required)
  jamlib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/IYY9Siz8/versions/TLQnUGxQ/jamlib-fabric-1.3.6%2B1.20.1.jar";
    sha512 = "148c2df3e2a8321e9807f46c27f9b81753be478c5130921b5b5393e2b8ddda6314a75b7bfb9c7ac6ee4aafebdc2f8538aebff79b56890e907f37daf69b495f59";
  };

  # Lithostitched 1.4.11 (required)
  lithostitched = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/XaDC71GB/versions/9bbVphAR/lithostitched-fabric-1.20.1-1.4.11.jar";
    sha512 = "d8e840907e3f7326c1e6605b65c46eb4e920e4790ab4074884ad21913f0c097dcacf4b813091239eb58bd65b7c75b96d04bb4df6eec830f89a21e217e3c0fdec";
  };

  # Macaw's Windows 2.4.2 (required)
  macaws_windows = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/C7I0BCni/versions/dGiIkdi3/mcw-mcwwindows-2.4.2-mc1.20.1fabric.jar";
    sha512 = "b74acb9cc9796a9993efc26d972ffdb5a648d072f238e0ddb7ab27788833ff44b0c68b334785d341a6c6fa29fadaf7acea0d79ae43c35d5f25b7279b1423a196";
  };

  # Moonlight 1.20-2.16.31 (required)
  moonlight = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/twkfQtEc/versions/u8CMlTGv/moonlight-1.20-2.16.31-fabric.jar";
    sha512 = "ae168575f29885c313aec416dd749f6a6687589756bb5402f99ea8c5e7ed953d7a96f7d334def53005ad388f2045e0dff68c773ef6313a458447a493bd4a4114";
  };

  # Nature's Compass 1.20.1-2.6.0-fabric (required)
  natures_compass = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/fPetb5Kh/versions/3dox9JXF/NaturesCompass-1.20.1-2.6.0-fabric.jar";
    sha512 = "d43c93dd476803bba76ab2efe16ff0df199c2dae425be513c0a35561c209bfac781062ee3f8cfab2a9987a6758aa04b5d7d2f9f2cb222aba70fceb59af786eb9";
  };

  # Rechiseled 1.2.4 (required)
  rechiseled = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/B0g2vT6l/versions/kxASWLSw/rechiseled-1.2.4-fabric-mc1.20.1.jar";
    sha512 = "d03c1e6857893d3f04fe9a331e57b2e49e099909b7bfccf8546b1e168b32edbfc26fc6d1eabb1c98cdc7b3b990546ff45324a324048d4629c0c91ded96da456e";
  };

  # Rechiseled: Create 1.1.0 (required)
  rechiseled_create = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/E6867niZ/versions/mxHMTC1M/rechiseledcreate-1.1.0-fabric-mc1.20.1.jar";
    sha512 = "601a75e0d42d1e099edfdcde11e563e161c8525cb93c425f8ab0c794662f778ac4b9bc4a58291ed86bdc75dcdbfe053313cb68d28fdd43ead14fae7c01fffabc";
  };

  # Resourceful Lib 2.1.29 (required)
  resourceful_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/G1hIVOrD/versions/UOdaYbhh/resourcefullib-fabric-1.20.1-2.1.29.jar";
    sha512 = "d3fcf5440c9359ee84cdec6ab198a6b2e10e5b1939995d2b12837ffdaa1f82d3caa80b14107cf02380718c65f20672b1faca3a498d2b41d79c79de34b2f7189b";
  };

  # Right Click Harvest 4.6.1+1.20.1 (required)
  right_click_harvest = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Cnejf5xM/versions/oTHOQtgH/rightclickharvest-fabric-4.6.1%2B1.20.1.jar";
    sha512 = "836f4cd5fa758f0774f314809bafb821a01b2a14dc90bcf3360997c6f26440825cb536e55929327bb9f7f4c02f296f35611c0af974e7960ab2fc7ea9ff20cfd0";
  };

  # Sophisticated Backpacks 1.20.1-3.23.4.5.110 (required)
  sophisticated_backpacks = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/ouNrBQtq/versions/Jk6o7s4h/sophisticatedbackpacks-1.20.1-3.23.4.5.110.jar";
    sha512 = "651a6121533e5693c26bde85141339cb89b5cfee5a750d67cbdad12a97a51ec8a0a3b3b59845afe9013b477fce9570f80ae0047e1c7054f458bc9c1b93ef748c";
  };

  # Sophisticated Core 1.20.1-1.2.7.15.166 (required)
  sophisticated_core = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/9jxwkYQL/versions/BP3CQI2v/sophisticatedcore-1.20.1-1.2.7.15.166.jar";
    sha512 = "892dda2bfa2a49ed66e869877fc6309cfc3af11fe61859c3b1be341baf689a693fda30902dec5c9ec6f737fd8fe451615ceb3d1c31c51e40c38e68b59dfcf134";
  };

  # SuperMartijn642's Config Lib 1.1.8+a (required)
  supermartijn642_config_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/LN9BxssP/versions/Ur02nrUT/supermartijn642configlib-1.1.8a-fabric-mc1.20.jar";
    sha512 = "bccd2d3e55a70c7d4c1aedaa9e85d6d0039e982ebdab40bc2aeba4b27a5112859f7a05c342c3c9575ff5d8ced769d1feffb104ecdd4d19cac8afba9ea2017c52";
  };

  # SuperMartijn642's Core Lib 1.1.21 (required)
  supermartijn642_core_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/rOUBggPv/versions/VfNphaSv/supermartijn642corelib-1.1.21-fabric-mc1.20.1.jar";
    sha512 = "6445f4c16cc120fb2fb4feb70de9f9cc0a303570dc5b2b330b8dd767807a90e04afd2c7cb6f512fad26707819dc9476f203ffd971b2af8c04fa53f8d0dce1391";
  };

  # Tectonic 3.0.17 (required)
  tectonic = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/lWDHr9jE/versions/mz3wlQKd/tectonic-3.0.17-fabric-1.20.1.jar";
    sha512 = "9a11047ed0e981bb60c230d00ec5d88bf3968119df808e9c55678cab94f8fa5005cdd916799dfd641e0ad60a1b937b4554c71c19d7b3d0f61b94f5135cbf377a";
  };

  # Terralith 2.5.4 (required)
  terralith = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/8oi3bsk5/versions/WeYhEb5d/Terralith_1.20.x_v2.5.4.jar";
    sha512 = "885e171d8b34aae7e142f082d0364285ec5a8e8342f11c60d341f7a94083d5a42c4e30612fe4f9f64d57b484396a3dff3a224e2a2497d4ced8d22f2ad6cd561d";
  };

  # Towns and Towers 1.12 (required)
  towns_and_towers = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/DjLobEOy/versions/7ZwnSrVW/Towns-and-Towers-1.12-Fabric%2BForge.jar";
    sha512 = "ed734046c356bb996b628c2e0c47e64ba598c87016591fd77533069de68f27b8bfdcd2173d7d3db97f1981ebb806133c3d1751c330d539ade3d6c37ed2d5598f";
  };

  # Waystones 14.1.20 (required)
  waystones = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/LOpKHB2A/versions/qHh09oyJ/waystones-fabric-1.20.1-14.1.20.jar";
    sha512 = "9fa12a0711d926292a5a2a5a63c7259b14bd3cc22fd48a18fd8e9dea564b9ea735ab3d34f043889331502acc7c214083e849d0e0d5e8f66e53127d230baab74d";
  };

  # FerriteCore 6.0.1 (performance)
  ferritecore = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/uXXizFIs/versions/unerR5MN/ferritecore-6.0.1-fabric.jar";
    sha512 = "9b7dc686bfa7937815d88c7bbc6908857cd6646b05e7a96ddbdcada328a385bd4ba056532cd1d7df9d2d7f4265fd48bd49ff683f217f6d4e817177b87f6bc457";
  };

  # Lithium 0.11.4 (performance)
  lithium = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/iEcXOkz4/lithium-fabric-mc1.20.1-0.11.4.jar";
    sha512 = "31938b7e849609892ffa1710e41f2e163d11876f824452540658c4b53cd13c666dbdad8d200989461932bd9952814c5943e64252530c72bdd5d8641775151500";
  };

  # ModernFix 5.25.2+mc1.20.1 (performance)
  modernfix = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/nmDcB62a/versions/rPmgLeZC/modernfix-fabric-5.25.2%2Bmc1.20.1.jar";
    sha512 = "878e39d182767ffd08ad6a3539fae780739129db133abe02b9b73dc3df6e1ac9ddbe509620356b0aae5e7bfbed535d0e18741703334317a16fefef820269da2d";
  };
}
