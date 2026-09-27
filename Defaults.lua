local _, ns = ...

-- Defaults for the first run and for "Restore all" / "Restore category".
-- Customise in game under Options > AddOns > Charades, not here.
-- Every emote listed here plays an animation.
ns.DefaultFavorites = { "/sit", "/point", "/wave", "/dance", "/cheer", "/bow" }

ns.DefaultCategories = {
    {
        id = "greetings",
        title = "Social",
        icon = "@group",
        items = {
            { label = "Wave", action = "/wave", icon = "@wave" },
            { label = "Hello", action = "/hello", icon = "@hello" },
            { label = "Bye", action = "/bye", icon = "@bye" },
            { label = "Bow", action = "/bow", icon = "@bow" },
            { label = "Curtsey", action = "/curtsey", icon = "@curtsey" },
            { label = "Kneel", action = "/kneel", icon = "@kneel" },
            { label = "Salute", action = "/salute", icon = "@salute" },
            { label = "Thank", action = "/thank", icon = "@thank" },
            { label = "Talk", action = "/talk", icon = "@talk" },
            { label = "Exclaim", action = "/talkex", icon = "@talkex" },
            { label = "Ask", action = "/talkq", icon = "@ask" },
            { label = "Point", action = "/point", icon = "@point" },
            { label = "Nod", action = "/yes", icon = "@yes" },
            { label = "Shake head", action = "/no", icon = "@no" },
        },
    },
    {
        id = "moods",
        title = "Moods",
        icon = "@smile",
        items = {
            { label = "Dance", action = "/dance", icon = "@dance" },
            { label = "Cheer", action = "/cheer", icon = "@cheer" },
            { label = "Laugh", action = "/laugh", icon = "@laugh" },
            { label = "Applaud", action = "/applaud", icon = "@applaud" },
            { label = "Cry", action = "/cry", icon = "@cry" },
            { label = "Shy", action = "/shy", icon = "@shy" },
            { label = "Flex", action = "/flex", icon = "@flex" },
            { label = "Roar", action = "/roar", icon = "@roar" },
            { label = "Kiss", action = "/kiss", icon = "@kiss" },
            { label = "Flirt", action = "/flirt", icon = "@flirt" },
            { label = "Chicken", action = "/chicken", icon = "@chicken" },
            { label = "Rude", action = "/rude", icon = "@rude" },
        },
    },
    {
        id = "other",
        title = "Rest",
        icon = "@tent",
        items = {
            { label = "Sit", action = "/sit", icon = "@sit" },
            { label = "Lie down", action = "/lay", icon = "@lay" },
            { label = "Sleep", action = "/sleep", icon = "@sleep" },
            { label = "Eat", action = "/eat", icon = "@eat" },
            { label = "Drink", action = "/drink", icon = "@drink" },
            { label = "Feast", action = "/feast", icon = "@feast" },
        },
    },
    {
        id = "reactions",
        title = "Reactions",
        icon = "@confused",
        items = {
            { label = "Cackle", action = "/cackle", icon = "@cackle" },
            { label = "Confused", action = "/confused", icon = "@confused" },
            { label = "Gasp", action = "/gasp", icon = "@gasp" },
            { label = "Mourn", action = "/mourn", icon = "@mourn" },
            { label = "Plead", action = "/plead", icon = "@plead" },
            { label = "Ponder", action = "/ponder", icon = "@think" },
            { label = "Pray", action = "/pray", icon = "@pray" },
            { label = "Shrug", action = "/shrug", icon = "@meh" },
            { label = "Surrender", action = "/surrender", icon = "@surrender" },
            { label = "Victory", action = "/victory", icon = "@trophy" },
            { label = "Congrats", action = "/congrats", icon = "@congrats" },
        },
    },
    {
        id = "signals",
        title = "Signals",
        icon = "@alert",
        collapsed = true,
        items = {
            { label = "Attack target", action = "/attacktarget", icon = "@attacktarget" },
            { label = "Charge", action = "/charge", icon = "@charge" },
            { label = "Open fire", action = "/openfire", icon = "@openfire" },
            { label = "Flee", action = "/flee", icon = "@flee" },
            { label = "Follow me", action = "/followme", icon = "@followme" },
            { label = "Incoming", action = "/incoming", icon = "@incoming" },
            { label = "Heal me", action = "/healme", icon = "@healme" },
            { label = "Help me", action = "/helpme", icon = "@helpme" },
            { label = "Out of mana", action = "/oom", icon = "@oom" },
            { label = "Lost", action = "/lost", icon = "@lost" },
            { label = "Taunt", action = "/taunt", icon = "@taunt" },
            { label = "Insult", action = "/insult", icon = "@insult" },
        },
    },
}

-- Commands (and aliases) of emotes that play an animation, from the classic emote lists.
-- Used by the "Animated only" filter in the All emotes view.
ns.AnimatedEmoteCommands = {}
for command in string.gmatch([[
angry mad applaud applause bravo attacktarget bashful beg blow blush boggle bow bye farewell goodbye
cackle charge cheer chew eat chicken flap strut chuckle clap commend confused congrats congratulate
cry sob weep curious curtsey dance drink shindig feast flee flex strong flirt followme gasp giggle
gloat golfclap greet greetings grovel guffaw hail healme hello hi helpme incoming insult kiss kneel
lay laydown lie liedown lol lost mourn oom openfire party peon plead point ponder pray puzzled
question rasp roar rofl rude salute shrug shy sit sleep surrender talk talkex talkq taunt train
victory violin wave welcome yes no
]], "%S+") do
    ns.AnimatedEmoteCommands["/" .. command] = true
end
