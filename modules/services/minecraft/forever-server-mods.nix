# Generated from the minecraft.org server-side mod list for Forever.
# Mirrors the nix-minecraft symlinks.mods/linkFarmFromDrvs pattern.
{pkgs}: {
  # Immersive Paintings 0.6.13+1.20.1
  immersive_paintings = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/6txNkua3/versions/TOHB3jQz/immersive_paintings-0.6.13%2B1.20.1-fabric.jar";
    sha512 = "033119c1bcb7c7538f2adc79bb90925c32b8ffef0c22b5be768af096ac660c219a9bf268d9f7d613521f54a425803ac525498be342b8e902ccfaed352a5544aa";
  };

  # Ksyxis 1.4.3
  ksyxis = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/2ecVyZ49/versions/kL32PN9Q/Ksyxis-1.4.3.jar";
    sha512 = "55b1ec940910a6c36fa40595b0d7b8617e3a817c55ecb2d5c1ee54c026936d6f1a4bbe63228c60ebf75195bb14f3c9128c913ba949df2c5877b9b99d21bab9a4";
  };

  # Just Enough Items 15.20.0.133
  jei = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/u6dRKJwZ/versions/otj7cskZ/jei-1.20.1-fabric-15.20.0.133.jar";
    sha512 = "c8dc490de515fb740f107034613365b966ef4d82c714dbe7a88f7fd7f5a313334d354598207f93ec2ce0f3af9d506c74a1141b978b4fb3a2976019b55724bb0c";
  };

  # Xaero's Minimap fabric-1.20.1-26.2.0
  xaerominimap = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/1bokaNcj/versions/qiNlZLVo/xaerominimap-fabric-1.20.1-26.2.0.jar";
    sha512 = "ae1b08182f4dbd8dc0b9db07c05628cc3b18bd7a4821a919f99eae4463c113fee893b5b12deeb7664c30e323522d1a0ab4261846a80834cfde1e66bd374e795c";
  };

  # Xaero's World Map fabric-1.20.1-1.42.0
  xaeroworldmap = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/NcUtCpym/versions/aQ2PfUQK/xaeroworldmap-fabric-1.20.1-1.42.0.jar";
    sha512 = "d07365813010f29e7b5c30c575ea60d86d67b6f9de5c205b4ba0907b08c587c9501be05bafc27a803c7d7376b99f66156b88993568d65a6fd606ec0497da6ae7";
  };

  # Xaero's Maps x Waystones 2.11.1+1.20.1-fabric
  xaero_maps_waystones = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/iv2jCzkP/versions/Cxi0KL4f/xmxw-2.11.1%2B1.20.1-fabric.jar";
    sha512 = "d3b00f1f5b5678ec43a23056b3a051a26f7a5d64621739319ab0a4463b92ff0422b1b35e6eb8b2bc30f74aad5833ad7b4f40e4ee2f13dc0746508193fa7da52c";
  };

  # YetAnotherConfigLib 3.6.6+1.20.1-fabric
  yet_another_config_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/1eAoo2KR/versions/dvS5DjUA/yet_another_config_lib_v3-3.6.6%2B1.20.1-fabric.jar";
    sha512 = "20f282b3cdaec7c83a96840edb756336677c5816ed943145022f1ce1eafac0c9aa7c621939e15abe6f4309626738bc56d3d1b8434f5175d22e7409108630b02b";
  };

  # Sound Physics Remastered fabric-1.20.1-1.5.1
  sound_physics_remastered = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/qyVF9oeo/versions/sCsWXt85/sound-physics-remastered-fabric-1.20.1-1.5.1.jar";
    sha512 = "3889b1e8e5448b36321a63b631cba89fe4b519f05fe85c572e4bc891216d12d55381f139b7a1cd53e210bddfee7750882506a4b71508da585cf4b459605d80cb";
  };

  # YUNG's API 1.20-Fabric-4.0.6
  yungs_api = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Ua7DFN59/versions/lscV1N5k/YungsApi-1.20-Fabric-4.0.6.jar";
    sha512 = "90fea70f21cd09bdeefe9cb6bd23677595b32156b1b8053611449504ba84a21ee1e13e5a620851299090ce989f41b97b9b4bdc98def1ccecb33115e19553c64e";
  };

  # YUNG's Better Dungeons 1.20-Fabric-4.0.4
  yungs_better_dungeons = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/o1C1Dkj5/versions/nidyvq2m/YungsBetterDungeons-1.20-Fabric-4.0.4.jar";
    sha512 = "02ee00641aea2e80806923c1d97a366b82eb6d6e1d749fc8fb4eeddeddea718c08f5a87ba5189427f747801b899abe5a6138a260c7e7f949e5e69b4065ac5464";
  };

  # YUNG's Better Mineshafts 1.20-Fabric-4.0.4
  yungs_better_mineshafts = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/HjmxVlSr/versions/qLnQnqXS/YungsBetterMineshafts-1.20-Fabric-4.0.4.jar";
    sha512 = "82d6e361ef403471beaaf2fa86964af541df167da56f53b820e5abfac693f63dd5d6c0aafbc9e9baa947b42a57c79f069ed6ede55e680a2523d2ca7f2e538b13";
  };

  # Amendments 1.20-2.2.5
  amendments = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/6iTJugQR/versions/wNje5tQz/amendments-1.20-2.2.5-fabric.jar";
    sha512 = "59551bf46957fcde18231a226a614a5c357a140e18c4230e8132a24140fd27b0c95eb8228073d7ea024035b3ca195e4d6e3b06679b6731d2bac294a683cb299d";
  };

  # AppleSkin 2.5.2+mc1.20.1
  appleskin = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/EsAfCjCV/versions/N5XeV21r/appleskin-fabric-mc1.20.1-2.5.2.jar";
    sha512 = "712ca0f86050ab3c6dbdbe62c5d9fabe77837d70529d1cd686f915a5f09d3a4f71ad4d3866984fbdded63ae2eb1c1ceedfb3386253510ee3a54857f77677e4f4";
  };

  # Architectury 9.2.14+fabric
  architectury = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/lhGA9TYQ/versions/WbL7MStR/architectury-9.2.14-fabric.jar";
    sha512 = "4cb8f009fd522d68a795d2cf5a657bdbe248b32ba7c33cd968f5ab521e9d60e198f8a3f6c50e7d960a2b8f50375116be0db1fd44b5710ea758697d8ea70d15de";
  };

  # Ash API 3.0.2+1.20.1-fabric
  ash_api = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Q8xUICr6/versions/Cc4WFedk/ash_api-fabric-3.0.2%2B1.20.1.jar";
    sha512 = "0795d03df3ca585edc2dfcf69424c6465c957f7f7467d24903b187affda7f5fa28fd2a6af804206d7f3f80991d9d900450ad098bbc277f5f08068eae9b3bde89";
  };

  # Athena 3.1.2
  athena = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/b1ZV3DIJ/versions/mXJWSwbJ/athena-fabric-1.20.1-3.1.2.jar";
    sha512 = "e55d49348a9d944bbd19390c64a4f42a1375eaaf0cbd4d69b4f523e441d9d23ce9498c912db724260cde32a43b776832cb867161e0989995d974de7e19e12389";
  };

  # AttributeFix 21.0.5
  attributefix = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/lOOpEntO/versions/9PvB3nqH/AttributeFix-Fabric-1.20.1-21.0.5.jar";
    sha512 = "b81d4823077acc00a669a359ec2f1c49c3f42bc765e96c1a793ceed2f41517600aea29548bde8a2f5a8f5bcddd95f6ff8e49a64062a6148b12dfaa85c5781b2c";
  };

  # Balm 7.3.41+fabric-1.20.1
  balm = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/MBAkmtvl/versions/sWBQARQL/balm-fabric-1.20.1-7.3.41.jar";
    sha512 = "18d908991eb74c32c87ce95acf594c74cf3d319e4b3c56b12c811eb88409a3d048053082c4963c792c893210a6aadbf28c0959d75cfb74f63120bcc9c8ee7212";
  };

  # Bookshelf 20.2.15
  bookshelf = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/uy4Cnpcm/versions/A4nZEDyK/Bookshelf-Fabric-1.20.1-20.2.15.jar";
    sha512 = "560d3a96857aca8049a485525a73b393d475c7cecb0b6c30808d51192277e3cc18cc1471556e9bdbb11e4013ecc60428dc0040f2b42f43978b15e66701a56db4";
  };

  # Brewin And Chewin 3.0.6+1.20.1
  brewinandchewin = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/e4G0uSdm/versions/ZieRTW8y/brewinandchewin-3.0.6%2B1.20.1.jar";
    sha512 = "7e4fec99e60f500b98fbfd781c0d91dc3608f9801bc3c2c17aa840dc3f46059fce7dc28179528779736ef905083dca333389a42fc7f57fe635d6aadf0f128a36";
  };

  # Carry On 2.1.2.7
  carry_on = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/joEfVgkn/versions/Mkla4B3q/carryon-fabric-1.20.1-2.1.2.7.jar";
    sha512 = "ca96f56dba50ea4827ec7a15bc590ccb29aba01896550d3cb398bed18acdf469dd351cdc9312e4743f54955b3162e744c58d76c88eb79b1e5e5b4570f5b33c64";
  };

  # Chef's Delight 1.0.4-fabric-1.20.1
  chefs_delight = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/pvcsfne4/versions/XYvlR0wq/chefs-delight-1.0.4-fabric-1.20.1.jar";
    sha512 = "bb32aa5408deacd405803341aa84ef551c8b6da8b39b7401faba1b0c7689004f6315369aced11a545e4ed31ee44967c0c68448dc5bb46d1dc05ebc8b6fee7be2";
  };

  # Chipped 3.0.7
  chipped = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/BAscRYKm/versions/pwyEaKDs/chipped-fabric-1.20.1-3.0.7.jar";
    sha512 = "5e12cc2ac7aec827a06fb9358fa53a25040428ae0f192a96305b129b084073154a6ae862d6875f6a02fe89a7a11d253049ce90b292f4c4ab2c72a9c94b93c9b0";
  };

  # Chunk Loaders 1.2.9-fabric-mc1.20.1
  chunkloaders = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/t1VgucWo/versions/muWpIAch/chunkloaders-1.2.9-fabric-mc1.20.1.jar";
    sha512 = "41fab2c1be721229e6cafd9437db21e742ae83eb9cb9357d8d6880655f68b21a9d5e0208ec7c63dd4cba1a5976e8c5915a5f384a6172fbb5b3e257a1a80630bd";
  };

  # Cloth Config 11.1.136+fabric
  cloth_config = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/9s6osm5g/versions/2xQdCMyG/cloth-config-11.1.136-fabric.jar";
    sha512 = "2da85c071c854223cc30c8e46794391b77e53f28ecdbbde59dc83b3dbbdfc74be9e68da9ed464e7f98b4361033899ba4f681ebff1f35edc2c60e599a59796f1c";
  };

  # Clumps 12.0.0.4
  clumps = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Wnxd13zP/versions/hefSwtn6/Clumps-fabric-1.20.1-12.0.0.4.jar";
    sha512 = "2235d29b1239d5526035bffd547d35fe33b9e737d3e75cd341f6689d9cd834d0a7dc03ed80748772162cd9595ba08e7a0ab51221bc145a8fd979d596c3967544";
  };

  # Collective 1.20.1-8.39-fabric+forge+neo
  collective = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/e0M1UDsY/versions/ZrHXYjUf/collective-1.20.1-8.39.jar";
    sha512 = "8772b683cb4d4d5ec15a995c717dec553d0ab07f43f310fc5e34de40216ad90abc4aaa22b035a0c387c35b9804655fdeda0edca8ced45ee9588f7b6a8e3a0e85";
  };

  # Comforts 6.4.0+1.20.1
  comforts = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/SaCpeal4/versions/pMr60Kkq/comforts-fabric-6.4.0%2B1.20.1.jar";
    sha512 = "c1796378b47aa03544b772d2b631d7387e4365ba0c0a3468dc5e78348d26e0406bd015b530e0acab679e090310aafd201a106e519d3b9e32b26e0db9928b04be";
  };

  # C2ME 0.2.0+alpha.11.18+1.20.1
  c2me = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/VSNURh3q/versions/fyt7FtgA/c2me-fabric-mc1.20.1-0.2.0%2Balpha.11.18.jar";
    sha512 = "5068a570cde47f105ec17bde14d0004c5f5d3f73b89d8e23a8ac5955a35f4a0dc59ff1d9e0626bfb29e04a7329dc0e9e089f41d637aff6843a6cd43d0573ece9";
  };

  # Create 6.0.8.1+build.1744-mc1.20.1
  create = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Xbc0uyRg/versions/HAqwA6X1/create-fabric-6.0.8.1%2Bbuild.1744-mc1.20.1.jar";
    sha512 = "6edaddb93bc87bf8204376d3ceddd3e3dfec1d716556a5925802f2ade59ce5a660ded50088fa94188842ff83fc29445363dfa5d423e425b1574092833b6fa896";
  };

  # Create Crafts and Additions fabric-1.20.1-1.3.4
  create_crafts_additions = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/kU1G12Nn/versions/KIAYldwh/createaddition-fabric%2B1.20.1-1.3.4.jar";
    sha512 = "30183dc89d483feb1f84647661ca97ef9bcc917a50dc1a38d5d034d176339fae3cc92fce7d60ae73b0bdb5134b7dfe4098e4237d818bc64d304469bb0e6cff10";
  };

  # Create Deco 2.1.1-1.20.1-Fabric
  create_deco = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/sMvUb4Rb/versions/OHgy53E6/createdeco-2.1.1-1.20.1-fabric.jar";
    sha512 = "96153a62eac6c98d80a29ff5186cf38c304ffaa0463867c6ac6826db8b3234230e78503dcbbac2bc81d467c9f2a07d4fb3b1908d7b6e85d775aabc1492c682d1";
  };

  # Create Jetpack 4.4.2-fabric
  create_jetpack = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/UbFnAd4l/versions/DEajn0Rs/create_jetpack-fabric-4.4.2.jar";
    sha512 = "7dcb0445769ad7c21cf5538b20e0bac2c82c7cc217763466474edec5c4ebbf4e8739ba4345d1cc193e176b6abada95abc1492d50c646bd8f714e31da059dd0ec";
  };

  # Create Slice and Dice 3.5.2-fabric
  create_slice_dice = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/GmjmRQ0A/versions/g0GPaHDq/sliceanddice-fabric-3.5.2.jar";
    sha512 = "080b4d8863e66e1eef7f767c2a674c3e860b5fb91abd7906301f180f6b321d60132f2b3b7089b17d75705888813a73eabac4c8a796b80938f6acda4b6f662692";
  };

  # Create Copycats+ 3.0.7+mc.1.20.1-fabric
  create_copycats = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/UT2M39wf/versions/dMrxOciv/copycats-3.0.7%2Bmc.1.20.1-fabric.jar";
    sha512 = "024d5aaacb96a73afe0c2d3810e7fbc0263bef2cd296f2b7b90593700e3ff9414f72e05e4a5301eee5bf8e337c6bab89d69bfd79d9ff0956ef207eb6639cf66c";
  };

  # Create Interiors 1.20.1-fabric-0.6.0
  create_interiors = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/r4Knci2k/versions/o01QffwP/interiors-1.20.1-fabric-0.6.0.jar";
    sha512 = "dc54c24d378cec5414005e383e6112642fa00f938e47a3c508ea8090b51cabb669d08d519f0de86f24b45563f3a52c1d6022d9b9094b977b0ea713bde257202e";
  };

  # Create New Age 1.2.0+mc1.20.1
  create_new_age = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/FTeXqI9v/versions/R4ZMqkxF/create-new-age-1.2.0%2Bfabric-mc1.20.1.jar";
    sha512 = "2376dd48c4fe9d4b0d2130aff93809a18c8305b52e7bcb18663bd03bfed18cc7452f3b8487bb4448aedb250207f2da3070c35becb7a38970fe7860326701285e";
  };

  # Create Steam n Rails 1.7.2+fabric-mc1.20.1
  create_steam_rails = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/ZzjhlDgM/versions/PEA8dAwJ/Steam_Rails-1.7.2%2Bfabric-mc1.20.1.jar";
    sha512 = "dacd75c3461f014f2a7caae77075b36c189e38eb23d887bfbd6f6ad66b27eeb699ee72908a4c973f8abbf32f35c0110bbb37d54e71dbdccbd676bc5c781339ec";
  };

  # Create Transmission 1.2.1+fabric-create6-1.20.1
  create_transmission = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/QFCkBuIh/versions/avB9AMPx/createtransmission-1.2.1%2Bfabric-create6-1.20.1.jar";
    sha512 = "7c2408b8a61cff61ad349981dae244b471da9c46bbb401b6cbf8dd624b2d28b14bb1a6dc5ada54f982993bfabfbb3bb29119fc1a6357b64500221fe6fc9c1333";
  };

  # CreativeCore 2.12.39
  creativecore = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/OsZiaDHq/versions/XdbR4wAI/CreativeCore_FABRIC_v2.12.39_mc1.20.1.jar";
    sha512 = "2368a12742ef1f1b1a033c6c6f68a953e0b9b0a2ca5d0cb092cd901be411edcbcd9a9c323d07b34957b208cefdb1670aacd31bdde2e522c8aca7cb7dc51c103c";
  };

  # Cristel Lib 1.1.5-fabric
  cristel_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/cl223EMc/versions/tBnivdbu/cristellib-1.1.5-fabric.jar";
    sha512 = "50ac2ac365932c5ea43a8baa67c2509292ae810fbe15848f202160c0bac3ef5ae648f175ae93436a9226e5b082cec562fab8da17c524bb642360aa859ef52652";
  };

  # Damiennes Bits n Bobs 0.1
  damiennes_bits = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/VtqzpOUa/versions/kIxEA1Jv/damiennes-bits-n-bobs-0.1.jar";
    sha512 = "315666ac915c16c3aaa8fd97147abadcaf7755d5897b47323105763e62efc8e95edcec8f87e06075150d2bf01817980ee027e3911d365540e74f87a15277413a";
  };

  # EnchantmentDescriptions 17.1.21
  enchantmentdescriptions = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/UVtY3ZAC/versions/YWWrhjUf/EnchantmentDescriptions-Fabric-1.20.1-17.1.21.jar";
    sha512 = "d5fc1b9cf448372dc1c904e7a61cc78cc796353ae97b277c4f37ba57527bb39021a0f869e676e12b38e1e539ae6f96df63fe10d7dafc3428ed82dca052ef55a1";
  };

  # Every Compat 1.20-2.9.24-fabric
  every_compat = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/eiktJyw1/versions/wJfnAofM/everycomp-1.20-2.9.24-fabric.jar";
    sha512 = "4df6329513368958b4bb55607732216f9a7599a83cfcbe1ac746e483b37b4ff01fd1f91c16eb81dc2e667c568f68208dd44005d9ceb1c5c1766e540e636a5d3e";
  };

  # Explorers Compass 1.20.1-2.6.0-fabric
  explorers_compass = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/RV1qfVQ8/versions/qD2j03H6/ExplorersCompass-1.20.1-2.6.0-fabric.jar";
    sha512 = "91679584c85dc4583996bb47202bbaaf93abf9678526d8a4360ae7b8c708508dfe5abc5cefc26f63a4211fef80d2aa8005bc97a244690e78f903e11a035d4161";
  };

  # Fabric API 0.92.9+1.20.1
  fabric_api = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/hu6gukgT/fabric-api-0.92.9%2B1.20.1.jar";
    sha512 = "9437e8561c0ce83031607f3015a4d487553c4cdd22ec91e2c874976139d1dcfd3ef909f78b89e8c3a6c35fdab6d79b34ed9624c3462ed2dfbaa85188b7249c02";
  };

  # Fabric Language Kotlin 1.13.12+kotlin.2.4.0
  fabric_language_kotlin = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Ha28R6CL/versions/Pd0xrHCw/fabric-language-kotlin-1.13.12%2Bkotlin.2.4.0.jar";
    sha512 = "ca238ee480dfb237062200fd300be493d022e0837b6998c15807e01488b2a30d5ba4731e5c6d05a5333719c8923a1cb84c06fd6fa45aa88ced492ddb5b40906f";
  };

  # Farmers Delight 1.20.1-2.4.1
  farmers_delight = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/7vxePowz/versions/Z8UNayLO/FarmersDelight-1.20.1-2.4.1%2Brefabricated.jar";
    sha512 = "4fa3d8756af6df2135f19b6b78972b098e75fbfb189252288f782ad00c2a56ce6b12320e8fe8975c250f0cc001daeafb24a91bb1c09717c01302225807599450";
  };

  # FerriteCore 6.0.1
  ferritecore = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/uXXizFIs/versions/unerR5MN/ferritecore-6.0.1-fabric.jar";
    sha512 = "9b7dc686bfa7937815d88c7bbc6908857cd6646b05e7a96ddbdcada328a385bd4ba056532cd1d7df9d2d7f4265fd48bd49ff683f217f6d4e817177b87f6bc457";
  };

  # Forge Config API Port v8.0.3-1.20.1-Fabric
  forgeconfigapiport = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/ohNO6lps/versions/HvR3IdRE/ForgeConfigAPIPort-v8.0.3-1.20.1-Fabric.jar";
    sha512 = "15144d6d7b74dfbe2eede6e3b0aa0c841670be1bd6121608bc28f3b1e46846ccd36b506060a081c988da96cf46fce8bf2e55601e3934b9a52d22dc2fa6cbfd32";
  };

  # Fusion 1.3.5-fabric-mc1.20.1
  fusion = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/p19vrgc2/versions/skGTd13F/fusion-1.3.5-fabric-mc1.20.1.jar";
    sha512 = "e370a66166e1b5e7968cb1fe074f30375d5dc87d0c74239bad5af2ef6382d6f0e254adfe0b754fdde66920139c390836978189be15e6830f7f4739e6789808d3";
  };

  # Handcrafted 3.0.6
  handcrafted = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/pJmCFF0p/versions/NRw0CDAc/handcrafted-fabric-1.20.1-3.0.6.jar";
    sha512 = "92c3b47c635196d0991831ce64e2c47bd9d666ee6213bbba87b8f0214cccbba626a564ad130ec0336e94936568dce462d1ff6ca726a81134518795709632602e";
  };

  # Jade 11.13.1+fabric
  jade = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/nvQzSEkH/versions/drol2x1P/Jade-1.20-Fabric-11.13.1.jar";
    sha512 = "048029727a30462abc8e43ecae2d5178ab653783c6dbcb2bd7c4c9cc1bb7c7a2ad5267ca3f89757f5b716da3f653b8e60ed8f46497917f26f094acc8f7dd7dc9";
  };

  # Jade Addons 5.5.2+fabric
  jade_addons = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/fThnVRli/versions/rVVb4MNE/JadeAddons-1.20.1-Fabric-5.5.2.jar";
    sha512 = "418ae81ffe7d104707c20ef616f2a75f66daf9e2b7eb5d838b4053634d42719da24d9481954fc06d6882bb408acf857f8c53ff97cc7afd97bc2f5d22173d7094";
  };

  # JamLib 1.3.6+1.20.1-patch.1
  jamlib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/IYY9Siz8/versions/wdcx00dY/jamlib-fabric-1.3.6%2B1.20.1-patch.1.jar";
    sha512 = "86a435a8ff50c3fee7b9874e518a4b10e708f085096af69be57fc429a42b0a6b17af6c3cb2baed21c27bb9406bddf90aa5a28718389d7e2e323d5388ffd58a0c";
  };

  # Lithium mc1.20.1-0.11.4-fabric
  lithium = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/iEcXOkz4/lithium-fabric-mc1.20.1-0.11.4.jar";
    sha512 = "31938b7e849609892ffa1710e41f2e163d11876f824452540658c4b53cd13c666dbdad8d200989461932bd9952814c5943e64252530c72bdd5d8641775151500";
  };

  # M.R.U 1.0.30+1.20.1-fabric
  mru = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/SNVQ2c0g/versions/argIe0Fr/mru-1.0.30%2B1.20.1-fabric.jar";
    sha512 = "72df81af1019f62bf00c62fdfa983b0bf0d683b66a5662db61082ce7449455ee2201c57fc58b397cea961844fe7949326932b7fd33710239b8cc0277516e914a";
  };

  # Macaws Bridges 3.1.2
  macaws_bridges = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/GURcjz8O/versions/bt7noi5F/mcw-bridges-3.1.2-mc1.20.1fabric.jar";
    sha512 = "1603f9559e097dda91d16a35c841fefe91eefb04b7e52926ac64cdf5edf9def2219f13fb27561b1afb03ad7aeeee3d85c6aa48e009de26ac45aab555feb25d2e";
  };

  # Macaws Fences and Walls 1.2.1
  macaws_fences = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/GmwLse2I/versions/bL1sIm2E/mcw-mcwfences-1.2.1-mc1.20.1fabric.jar";
    sha512 = "578dfc810c5aee7df4bd1ba04044d914a6a772a6dab27c389f61ee4c9a7df576c5b8e620dc84c1643be2f34140cc19b8bd50a917fad268300af86b4000f9581e";
  };

  # Macaws Roofs 2.3.2
  macaws_roofs = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/B8jaH3P1/versions/BMjP4VXn/mcw-roofs-2.3.2-mc1.20.1fabric.jar";
    sha512 = "0c7f5297750d4518b11a48fb87c41360288f239dcca12426ed39a500c23d7b2d9303daa2f488bd08dc8d7cf5260d6d8b705c89ec5e4477506d545ef8a0b26ece";
  };

  # Macaws Stairs and Balconies 1.0.2
  macaws_stairs = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/iP3wH1ha/versions/zg1JyUwM/mcw-mcwstairs-1.0.2-mc1.20.1fabric.jar";
    sha512 = "1edd6c3af57ef0d21dc145eaf2b182f7a81c8fb72cee8e2f84050fad9d9c3a93a7743f2e5690cc15b1c8f0c7234d3f0634945c634b8267383001eea49e052f70";
  };

  # Macaws Windows 2.4.2
  macaws_windows = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/C7I0BCni/versions/dGiIkdi3/mcw-mcwwindows-2.4.2-mc1.20.1fabric.jar";
    sha512 = "b74acb9cc9796a9993efc26d972ffdb5a648d072f238e0ddb7ab27788833ff44b0c68b334785d341a6c6fa29fadaf7acea0d79ae43c35d5f25b7279b1423a196";
  };

  # MidnightLib 1.9.3+1.20.1-fabric
  midnightlib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/codAaoxh/versions/rXX4FCV8/midnightlib-fabric-1.9.3%2B1.20.1.jar";
    sha512 = "a35f2fb5f186622c437afbff5887a67191453926f187455216302647a9b2699c8e3fc1c9152deda1dd02f212a7986f50daf6fe3fe53e5d57baaab3b468e11f05";
  };

  # ModernFix 5.25.2+mc1.20.1
  modernfix = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/nmDcB62a/versions/rPmgLeZC/modernfix-fabric-5.25.2%2Bmc1.20.1.jar";
    sha512 = "878e39d182767ffd08ad6a3539fae780739129db133abe02b9b73dc3df6e1ac9ddbe509620356b0aae5e7bfbed535d0e18741703334317a16fefef820269da2d";
  };

  # Moonlight 1.20-2.16.34-fabric
  moonlight = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/twkfQtEc/versions/IYl8kNb4/moonlight-1.20-2.16.34-fabric.jar";
    sha512 = "58645f07fab0d7f4fb34810023276c5d3e6a4ab58fee9c179060d5f8435d609b8c990b402a3e5be1769ff45b10fadf4db371b2ae7eb6db7b14095ebaab379aa9";
  };

  # Natures Compass 1.20.1-2.6.0-fabric
  natures_compass = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/fPetb5Kh/versions/3dox9JXF/NaturesCompass-1.20.1-2.6.0-fabric.jar";
    sha512 = "d43c93dd476803bba76ab2efe16ff0df199c2dae425be513c0a35561c209bfac781062ee3f8cfab2a9987a6758aa04b5d7d2f9f2cb222aba70fceb59af786eb9";
  };

  # Owo Lib 0.11.2+1.20
  owo = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/ccKDOlHs/versions/zyOBB7J4/owo-lib-0.11.2%2B1.20.jar";
    sha512 = "807e4a3daf493e92c5ff0d5657efbba2a4e0cd2a9b753f2d6f153422629415f189345842a6dd258c87d4c02ebf38950a517bcd8a7ed929af6ed6485ae46cf77e";
  };

  # Pandas Falling Trees 0.14.0
  pandas_falling_trees = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/i2kUe4lq/versions/wW9lDbIZ/fallingtrees-fabric-1.20.1-0.14.0.jar";
    sha512 = "e71e1c7f6688c0d454a66d359f310106be548ad84aa6590cfb2cbba5680861241d2b7047be9ebe318fb6de495d82d2bd1c926e916ffd9772f3666236ce6bf5d1";
  };

  # PandaLib 0.6.1
  pandalib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/mEEGbEIu/versions/MH98GMaH/pandalib-fabric-1.20.1-0.6.1.jar";
    sha512 = "15a6d561200ab2a411112b649d07469dbfa7cccb872a0580438c3f38221eeda3f3604667ddd6b98bdd8ccc3f63b95ce87f5c1081412ed3cb87906e5399854556";
  };

  # Pet Names 1.20.1-3.5-fabric+forge+neo
  petnames = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/tOoh2eQm/versions/H9lHMDgD/petnames-1.20.1-3.5.jar";
    sha512 = "a701ba0c3f410f5edd642a8c2d7d11d7832bb1e424d5cae9bb8f105a63181d83bec8fe6811ef098ca63767b048ae5371c14c62fe0b7ee3a45593d0c32e4a4d8e";
  };

  # Player Graves 1.0.0
  player_graves = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/YQybd3R7/versions/r8smB0qB/graves-fabric-1.20-1.20.1-1.0.0.jar";
    sha512 = "4d7f0d6cacfe87ca447cf02b7de43929b63d40ea3c40649a4ac04ae06ab6aed986b8618dc2322fb895d5d4b1d52dacf4987e0e293a9a00d588fd456cb7e614f7";
  };

  # Rechiseled 1.2.5-fabric-mc1.20.1
  rechiseled = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/B0g2vT6l/versions/uBQ9cb0y/rechiseled-1.2.5-fabric-mc1.20.1.jar";
    sha512 = "25c714e0e3c18019703528c0b5f0e138bfc656bfcdb54aab946a518d3ac288620459ee896a277aa2e6ce94bd9abbf30663e8a0f50cfa82b28d65a7c1b9456401";
  };

  # Rechiseled Create 1.1.1-fabric-mc1.20.1
  rechiseled_create = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/E6867niZ/versions/L0upAoTY/rechiseledcreate-1.1.1-fabric-mc1.20.1.jar";
    sha512 = "11d914c8b7b789b96abfd65e92cff22f8e808da66ac1dd56efa0796cd50f68eb00a1c9486b76b42ec303a2be74f4ab01041d2b6c9c95e46acdb8f44167c1b3a1";
  };

  # Resourceful Lib 2.1.29
  resourceful_lib = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/G1hIVOrD/versions/UOdaYbhh/resourcefullib-fabric-1.20.1-2.1.29.jar";
    sha512 = "d3fcf5440c9359ee84cdec6ab198a6b2e10e5b1939995d2b12837ffdaa1f82d3caa80b14107cf02380718c65f20672b1faca3a498d2b41d79c79de34b2f7189b";
  };

  # Right Click Harvest 4.6.1+1.20.1
  rightclickharvest = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/Cnejf5xM/versions/oTHOQtgH/rightclickharvest-fabric-4.6.1%2B1.20.1.jar";
    sha512 = "836f4cd5fa758f0774f314809bafb821a01b2a14dc90bcf3360997c6f26440825cb536e55929327bb9f7f4c02f296f35611c0af974e7960ab2fc7ea9ff20cfd0";
  };

  # Shuffle 9.0.0+1.20.1-fabric
  shuffle = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/WUvGZLgB/versions/sPce9t3y/shuffle-fabric-9.0.0%2B1.20.1.jar";
    sha512 = "cb07cb657e60139cd2bdc1c2f447b420f439754f59f92abc0d16660d4d265a05445a0dee9c165acc1f9f8c49e02b416ea11e836a4b1f8b7c6db0dbf7c56f3ced";
  };

  # Shulker Box Tooltip 4.0.4+1.20.1-fabric
  shulkerboxtooltip = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/2M01OLQq/versions/gVxjsEiQ/shulkerboxtooltip-fabric-4.0.4%2B1.20.1.jar";
    sha512 = "65cdc8b565e5a7f9a855dd35c7c4b20daae0c6a5822e9a32dabd0f8fd4df6353c9fbd9d1437b83c6f7824e1c65ce466a82f70a7b7ef007bd54afa63718037043";
  };

  # Sophisticated Backpacks 1.20.1-3.23.4.5.110
  sophisticated_backpacks = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/ouNrBQtq/versions/Jk6o7s4h/sophisticatedbackpacks-1.20.1-3.23.4.5.110.jar";
    sha512 = "651a6121533e5693c26bde85141339cb89b5cfee5a750d67cbdad12a97a51ec8a0a3b3b59845afe9013b477fce9570f80ae0047e1c7054f458bc9c1b93ef748c";
  };

  # Sophisticated Core 1.20.1-1.2.7.15.166
  sophisticated_core = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/9jxwkYQL/versions/BP3CQI2v/sophisticatedcore-1.20.1-1.2.7.15.166.jar";
    sha512 = "892dda2bfa2a49ed66e869877fc6309cfc3af11fe61859c3b1be341baf689a693fda30902dec5c9ec6f737fd8fe451615ceb3d1c31c51e40c38e68b59dfcf134";
  };

  # SuperMartijn642 Config Lib 1.1.8a-fabric-mc1.20.1
  supermartijn642_config = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/LN9BxssP/versions/Ur02nrUT/supermartijn642configlib-1.1.8a-fabric-mc1.20.jar";
    sha512 = "bccd2d3e55a70c7d4c1aedaa9e85d6d0039e982ebdab40bc2aeba4b27a5112859f7a05c342c3c9575ff5d8ced769d1feffb104ecdd4d19cac8afba9ea2017c52";
  };

  # SuperMartijn642 Core Lib 1.1.21-fabric-mc1.20.1
  supermartijn642_core = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/rOUBggPv/versions/VfNphaSv/supermartijn642corelib-1.1.21-fabric-mc1.20.1.jar";
    sha512 = "6445f4c16cc120fb2fb4feb70de9f9cc0a303570dc5b2b330b8dd767807a90e04afd2c7cb6f512fad26707819dc9476f203ffd971b2af8c04fa53f8d0dce1391";
  };

  # Supplementaries 1.20-3.1.43-fabric
  supplementaries = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/fFEIiSDQ/versions/i7ejA878/supplementaries-1.20-3.1.43-fabric.jar";
    sha512 = "141b8c1358083b3804f4cd43c825050a32f0d96fd1502d6f880cf4f85dc8a79d781ab521dd30154d2ea4d7cae30c9e781ecd0b9138295fb2ca2513b667cf36de";
  };

  # Sushi Bar 0.2.2+1.20
  sushi_bar = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/tr2Mv6ke/versions/jr9lc3k8/sushi_bar-0.2.2%2B1.20.jar";
    sha512 = "d8619fe5e575e62eca86e898569df122eb5002914167cf75d7d61f17633ead9e3c6b4b7a3b00d2336964b21f299f653459fc1964440f6ad2d36011be5dc72889";
  };

  # Terralith 2.5.4
  terralith = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/8oi3bsk5/versions/WeYhEb5d/Terralith_1.20.x_v2.5.4.jar";
    sha512 = "885e171d8b34aae7e142f082d0364285ec5a8e8342f11c60d341f7a94083d5a42c4e30612fe4f9f64d57b484396a3dff3a224e2a2497d4ced8d22f2ad6cd561d";
  };

  # Towns and Towers 1.12
  towns_and_towers = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/DjLobEOy/versions/7ZwnSrVW/Towns-and-Towers-1.12-Fabric%2BForge.jar";
    sha512 = "ed734046c356bb996b628c2e0c47e64ba598c87016591fd77533069de68f27b8bfdcd2173d7d3db97f1981ebb806133c3d1751c330d539ade3d6c37ed2d5598f";
  };

  # Trade Cycling fabric-1.20.1-1.0.18
  trade_cycling = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/qpPoAL6m/versions/oKfFaQGY/trade-cycling-fabric-1.20.1-1.0.18.jar";
    sha512 = "e2b7949a66c6c1adecea8ce5eace8e96758c5d1c20350ff47d9a55f8e69b678debdc778414ee20f0b2444008c26666d4edc15bcc90934fced3191fa9c9db927c";
  };

  # Trinkets 3.7.2
  trinkets = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/5aaWibi9/versions/AHxQGtuC/trinkets-3.7.2.jar";
    sha512 = "bedf97c87c5e556416410267108ad358b32806448be24ef8ae1a79ac63b78b48b9c851c00c845b8aedfc7805601385420716b9e65326fdab21340e8ba3cc4274";
  };

  # Villager Names 1.20.1-8.5-fabric+forge+neo
  villagernames = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/gqRXDo8B/versions/2THA99E5/villagernames-1.20.1-8.5.jar";
    sha512 = "dff4f8cfdef8ad846e4d087f9cdf106fafd583cdcde064d3d891f7f404c8b71add509fb28bc0dcfaeb0bf9a77bc4eee919f9aa5882bfb535f9a09a351c3b8c42";
  };

  # Waystones 14.1.20+fabric-1.20.1
  waystones = pkgs.fetchurl {
    url = "https://cdn.modrinth.com/data/LOpKHB2A/versions/qHh09oyJ/waystones-fabric-1.20.1-14.1.20.jar";
    sha512 = "9fa12a0711d926292a5a2a5a63c7259b14bd3cc22fd48a18fd8e9dea564b9ea735ab3d34f043889331502acc7c214083e849d0e0d5e8f66e53127d230baab74d";
  };
}
