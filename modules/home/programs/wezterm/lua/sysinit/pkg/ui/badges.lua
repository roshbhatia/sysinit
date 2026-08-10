local M = {}

local NAMES = {
  "muadib",   "stilgar",  "chani",    "gurney",   "feyd",     "irulan",
  "alia",     "thufir",   "mentat",   "kwisatz",  "hayt",     "korba",    "scytale",
  "shrike",   "kassad",   "silenus",  "brawne",   "aenea",    "raul",
  "consul",   "ummon",    "moneta",   "sol",      "endymion", "templar",
  "aragorn",  "gandalf",  "samwise",  "legolas",  "gimli",    "boromir",
  "faramir",  "eowyn",    "galadriel","elrond",   "saruman",  "theoden",
  "frodo",    "merry",    "pippin",   "glorfindel","haldir",
  "kaladin",  "dalinar",  "szeth",    "jasnah",   "shallan",  "adolin",
  "wit",      "vin",      "elend",    "kelsier",  "sazed",    "spook",
  "breeze",   "marsh",    "nightblood","hoid",    "vasher",   "renarin",
  "lift",     "taravangian","navani",
  "hadrian",  "valka",    "pallino",  "lorian",   "bassander",
  "vorgossos","gibson",   "siran",    "elara",    "kharn",
  "logen",    "glokta",   "jezal",    "bayaz",    "ferro",    "dogman",
  "shivers",  "monza",    "cosca",    "friendly", "temple",   "caul",     "chella",
  "kvothe",   "denna",    "bast",     "auri",     "elodin",   "kilvin",
  "simmon",   "wilem",    "devi",     "tempi",    "felurian", "ambrose",
  "case",     "molly",    "wintermute","armitage", "riviera",  "maelcum",  "flatline",
  "darrow",   "sevro",    "mustang",  "cassius",  "roque",    "victra",   "lysander",
  "severian", "thecla",   "dorcas",   "agia",     "baldanders","typhon",  "jonas",
  "jorg",     "makin",    "rike",     "sageous",  "miana",    "coddin",   "jalan",    "snorri",
  "maia",     "csevet",   "cala",     "beshelar", "setheris",
  "keogh",    "dragosani","zek",      "nathan",
  "alwyn",    "evadine",  "deckin",   "tiler",
  "vaelin",   "reva",     "nortah",   "caenis",   "barkus",
  "vis",      "emissa",   "callidus", "acqua",    "ulciscor",
  "eragon",   "saphira",  "arya",     "murtagh",  "brom",     "nasuada",  "roran",    "oromis",   "galbatorix",
  "kinch",    "galva",    "norrigal",
  "thomas",
  "ripley",   "newt",     "bishop",   "hicks",    "ash",      "hudson",   "vasquez",  "dallas",   "lambert",  "burke",
  "dutch",    "mac",      "blain",    "harrigan", "dillon",
  "deckard",  "rachael",  "roy",      "pris",     "gaff",     "joi",      "luv",
  "snake",    "otacon",   "meryl",    "liquid",   "ocelot",   "raiden",   "solidus",  "vamp",     "mantis",   "wolf",
  "quiet",    "paz",      "skull",
  "leon",     "claire",   "jill",     "wesker",   "ada",      "barry",    "chris",    "ethan",    "heisenberg",
  "dimitrescu",
}

function M.name(pane_id)
  local h = pane_id * 2654435761
  return NAMES[(h % #NAMES) + 1]
end

function M.color(pane_id, colors)
  local h = pane_id * 2654435761
  local slot = (h % 6) + 2
  if type(colors) == "table" then
    local a = colors.ansi or (colors.colors and colors.colors.ansi)
    if type(a) == "table" and a[slot] then return a[slot] end
    local b = colors.brights or colors
    if type(b) == "table" then return b[(h % 6) + 2] end
  end
  return nil
end
return M
