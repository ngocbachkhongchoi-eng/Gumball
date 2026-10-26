--[[
    Gumball - Blox Fruits (Sea 1)
    Tab: Fam | Di chuyển | Mua | ESP | Aim | Cài đặt
    Key: GUMBALL-<1H|24H|1M|1Y>-xxxx-xxxxxx  (1 key = 1 máy khi đã cấu hình ServerUrl)
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)
local player = Players.LocalPlayer

local genv = (getgenv and getgenv()) or _G
if genv.GumballUnload then pcall(genv.GumballUnload) end

----------------------------------------------------------------
-- CẤU HÌNH
----------------------------------------------------------------
local CONFIG = {
    -- Địa chỉ máy chủ key, ví dụ "http://127.0.0.1:3000" hoặc "https://ten-mien-cua-ban.com".
    -- Để trống = chế độ offline (KHÔNG khóa key theo máy).
    ServerUrl = "",
    -- PHẢI giống SECRET của file admin và server.
    Secret = "gb#9xQ!zK2$mW7",
    KeyFile = "gumball_key.txt",
    RecordFile = "gumball_keys.txt",
    MaxAttempts = 5,
    LockSeconds = 30,
    Sea1PlaceId = 2753915549,
    MaxQuestLevel = 699,
    MonsterFolder = "Enemies",
    FarmFlySpeed = 350,
    FastClicks = 2,
    EspMax = 20,
    AuraRange = 70,
    AuraMax = 8,
    AuraProbeGap = 8, -- giây tối thiểu giữa 2 lần thử lại đánh ẩn
    BringMax = 5,
    Weapons = { { tip = "Melee" }, { tip = "Sword" }, { tip = "Blox Fruit" }, { tip = "Gun" } },
}
local DURATIONS = { ["1H"] = 3600, ["24H"] = 86400, ["1M"] = 2592000, ["1Y"] = 31536000 }

local C = {
    Bg = Color3.fromRGB(9, 9, 12), Panel = Color3.fromRGB(16, 16, 21), Row = Color3.fromRGB(23, 23, 30),
    RowHi = Color3.fromRGB(36, 30, 38),
    Red = Color3.fromRGB(226, 32, 44), RedHi = Color3.fromRGB(255, 84, 96), RedDark = Color3.fromRGB(110, 12, 22),
    Off = Color3.fromRGB(52, 52, 63), White = Color3.fromRGB(255, 255, 255), Gray = Color3.fromRGB(150, 150, 166),
    Green = Color3.fromRGB(90, 225, 130), Black = Color3.fromRGB(0, 0, 0),
    Gold = Color3.fromRGB(255, 208, 92), Purple = Color3.fromRGB(190, 135, 255),
}

----------------------------------------------------------------
-- LỖI + AN TOÀN + GHI LOG
----------------------------------------------------------------
local lastError = ""
local function logErr(e)
    lastError = tostring(e)
    warn("[Gumball] " .. lastError)
end
local dbgLog = {}
local function dbg(msg)
    dbgLog.seq = (dbgLog.seq or 0) + 1
    dbgLog[#dbgLog + 1] = string.format("[%s] %s", os.date("%H:%M:%S"), tostring(msg))
    if #dbgLog > 80 then table.remove(dbgLog, 1) end
end
local function guard(fn)
    return function(...)
        local ok, e = pcall(fn, ...)
        if not ok then logErr(e) end
    end
end

local function describe(v, depth)
    local t = typeof(v)
    if t == "Instance" then return "Instance<" .. v.ClassName .. ":" .. v.Name .. ">" end
    if t == "table" then
        if depth >= 3 then return "{...}" end
        local parts, n = {}, 0
        for k, x in pairs(v) do
            n = n + 1
            if n > 6 then parts[#parts + 1] = "..." break end
            parts[#parts + 1] = tostring(k) .. "=" .. describe(x, depth + 1)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    end
    if t == "string" then return "string(" .. #v .. "," .. v:sub(1, 8) .. ")" end
    return t .. ":" .. tostring(v)
end
local function describeArgs(pk)
    local out = {}
    for i = 1, pk.n do out[#out + 1] = describe(pk[i], 0) end
    return table.concat(out, " | ")
end

local function fmtNum(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (r:gsub("^,", ""))
end

----------------------------------------------------------------
-- NGÔN NGỮ (mục thiếu bản dịch sẽ tự dùng tiếng Anh)
----------------------------------------------------------------
local LANGS = {
    { v = "vi", name = "Tiếng Việt" }, { v = "en", name = "English" }, { v = "zh", name = "中文" },
    { v = "ja", name = "日本語" }, { v = "ko", name = "한국어" }, { v = "es", name = "Español" },
    { v = "pt", name = "Português" }, { v = "id", name = "Bahasa Indonesia" },
}
local T = {
    vi = {
        key_title = "Nhập key để mở menu", key_ph = "Nhập key...", key_ok = "Xác nhận",
        key_bad = "Key sai (còn %d lần thử).", key_lock = "Sai quá nhiều, chờ %d giây.",
        key_expired = "Key đã hết hạn.", key_used = "Key này đã kích hoạt trên máy khác.",
        key_net = "Không kết nối được máy chủ key.", key_check = "Đang kiểm tra...",
        key_offline = "Chế độ offline: key chưa bị khóa theo máy.", key_rate = "Thử quá nhanh, chờ một chút.",
        tab_fam = "Fam", tab_move = "Di chuyển", tab_shop = "Mua", tab_esp = "ESP", tab_aim = "Aim", tab_set = "Cài đặt",
        autofam = "AutoFam (tự nhận quest + đánh)", autostat = "Tự cộng điểm",
        stat_which = "Cộng điểm vào", stat_Melee = "Cận chiến", stat_Sword = "Kiếm", stat_Demon = "Trái ác quỷ",
        fast = "Đánh siêu nhanh", skills = "Dùng chiêu (Z X C V)", bring = "Tự gom quái", farm_style = "Kiểu fam", style_straight = "Fam thẳng", style_orbit = "Xoay vòng tròn", fallback_click = "Tự đánh thường khi đánh ẩn không ăn", sec_auto = "Tự động", sec_fight = "Chiến đấu", sec_show = "Hiển thị", sec_color = "Màu sắc", sec_fov = "Vòng FOV", weapon = "Vũ khí",
        sec_saber = "Nhiệm vụ đặc biệt", autosaber = "Auto Saber (cần cấp 200)",
        w_Melee = "Cận chiến", w_Sword = "Kiếm", w_Fruit = "Trái ác quỷ", w_Gun = "Súng",
        monster = "Chọn quái (Tất cả = tự theo quest)", all = "Tất cả", height = "Độ cao bay (tự nâng khi bị đánh)",
        fly = "Bay", flyspeed = "Tốc độ bay", run = "Chạy nhanh", runspeed = "Tốc độ chạy",
        esp_on = "Bật ESP", esp_players = "Người chơi", esp_mobs = "Quái", esp_box = "Khung",
        esp_name = "Tên", esp_dist = "Khoảng cách", esp_hp = "Thanh máu", esp_tracer = "Dây",
        esp_chams = "Tô sáng", esp_color = "Màu ESP", esp_tcolor = "Màu dây", esp_origin = "Gốc dây",
        o_bottom = "Dưới (thẳng lên)", o_center = "Giữa", o_top = "Trên",
        aim_on = "Aimlock", aim_part = "Ghim vào", p_head = "Đầu", p_body = "Người", p_feet = "Chân",
        aim_target = "Mục tiêu", t_players = "Người chơi", t_mobs = "Quái",
        aim_showfov = "Hiện vòng FOV", aim_fov = "Kích thước FOV (tối đa 360)",
        aim_fovcolor = "Màu vòng FOV", aim_smooth = "Độ mượt",
        lang = "Ngôn ngữ", unload = "Hủy script", unload_btn = "Hủy",
        antiban = "AntiBan cơ bản (luôn bật)", antiban_desc = "Chống kick AFK, nhịp đánh có độ trễ ngẫu nhiên.",
        errcopy = "Sao chép log lỗi", errcopied = "Đã sao chép", errnone = "Chưa có lỗi nào",
        time_left = "Còn lại", time_day = "ngày", expired_msg = "Key đã hết hạn, script dừng.",
        d_1H = "1 Giờ", d_24H = "1 Ngày", d_1M = "1 Tháng", d_1Y = "1 Năm",
        buy = "MUA", shop_hint = "Giá tham khảo, máy chủ game quyết định. Mua xong đồ vào thẳng kho.",
        c_sword = "Kiếm", c_gun = "Súng", c_acc = "Phụ kiện", c_skill = "Kỹ năng", c_style = "Võ", c_misc = "Khác",
        buying = "Đang mua %s...", buy_ok = "Đã mua %s (-%s)", farm_speed = "Tốc độ bay khi fam",
        sec_goto = "Bay tới người chơi", goto_btn = "Bay tới", goto_stop = "Dừng bay", goto_none = "Chưa chọn ai",
        goto_sel = "Đã chọn: %s", sec_extra = "Tiện ích", fpsboost = "Giảm lag (FPS boost)", autobuso = "Tự bật Haki vũ trang",
        shop_fly = "Đang bay tới NPC bán: %s...", shop_nonpc = "Không thấy NPC bán %s, thử mua trực tiếp...",
        buy_fail = "Chưa mua được %s: thiếu tiền hoặc thiếu điều kiện",
        st_ready = "Sẵn sàng", st_off = "Đã tắt AutoFam", st_respawn = "Chờ hồi sinh...",
        st_nomob = "Không thấy quái, đang chờ...", st_noweapon = "Không có vũ khí trong túi đồ",
        st_flyto = "Đang bay tới: %s", st_fight = "Đánh ẩn: %s %s", st_fastfight = "Đánh ẩn nhanh: %s %s",
        st_swing = "Đánh thường: %s %s", st_probe = "Đang thử đánh ẩn: %s",
        st_aura_wait = "Chờ mẫu đòn: hãy tự đánh quái 1 lần (%s)",
        st_wrongweapon = "Không có loại đã chọn, dùng %s", st_goquest = "Bay tới NPC nhận quest: %s",
        st_questok = "Đã nhận quest: %s", st_questfail = "Chưa nhận được quest, thử lại sau...",
        st_island = "Đang bay tới đảo có: %s", st_nospawn = "Không tìm thấy điểm sinh quái: %s",
        st_noquest = "Không có quest hợp cấp", st_sea = "Cảnh báo: không phải Sea 1",
        st_saber_lv = "Auto Saber cần cấp 200", st_saber_done = "Đã có Saber, dừng Auto Saber",
        st_saber_boss = "Saber: đang đánh Saber Expert", st_saber_plates = "Saber: giẫm 6 bàn đạp ở rừng",
        st_saber_torch = "Saber: lấy đuốc", st_saber_burn = "Saber: châm lửa sa mạc",
        st_saber_quest = "Saber: chuỗi nhiệm vụ (%s)", st_saber_room = "Saber: vào phòng Saber",
    },
    en = {
        key_title = "Enter key to open menu", key_ph = "Enter key...", key_ok = "Confirm",
        key_bad = "Wrong key (%d tries left).", key_lock = "Too many tries, wait %d s.",
        key_expired = "Key has expired.", key_used = "This key is already used on another device.",
        key_net = "Cannot reach the key server.", key_check = "Checking...",
        key_offline = "Offline mode: key is not locked to a device.", key_rate = "Too fast, wait a moment.",
        tab_fam = "Farm", tab_move = "Movement", tab_shop = "Shop", tab_esp = "ESP", tab_aim = "Aim", tab_set = "Settings",
        autofam = "AutoFarm (auto quest + fight)", autostat = "Auto stats",
        stat_which = "Add points to", stat_Melee = "Melee", stat_Sword = "Sword", stat_Demon = "Blox Fruit",
        fast = "Super fast attack", skills = "Use skills (Z X C V)", bring = "Auto bring mobs", farm_style = "Farm style", style_straight = "Straight", style_orbit = "Orbit circle", fallback_click = "Normal attack when silent hit fails", sec_auto = "Automation", sec_fight = "Combat", sec_show = "Display", sec_color = "Colors", sec_fov = "FOV circle", weapon = "Weapon",
        sec_saber = "Special quest", autosaber = "Auto Saber (needs level 200)",
        w_Melee = "Melee", w_Sword = "Sword", w_Fruit = "Blox Fruit", w_Gun = "Gun",
        monster = "Select mob (All = follow quest)", all = "All", height = "Hover height (auto-raises when hit)",
        fly = "Fly", flyspeed = "Fly speed", run = "Speed run", runspeed = "Run speed",
        esp_on = "Enable ESP", esp_players = "Players", esp_mobs = "Mobs", esp_box = "Box",
        esp_name = "Name", esp_dist = "Distance", esp_hp = "Health bar", esp_tracer = "Tracer",
        esp_chams = "Chams", esp_color = "ESP color", esp_tcolor = "Tracer color", esp_origin = "Tracer origin",
        o_bottom = "Bottom (straight up)", o_center = "Center", o_top = "Top",
        aim_on = "Aimlock", aim_part = "Aim at", p_head = "Head", p_body = "Body", p_feet = "Feet",
        aim_target = "Target", t_players = "Players", t_mobs = "Mobs",
        aim_showfov = "Show FOV circle", aim_fov = "FOV size (max 360)",
        aim_fovcolor = "FOV color", aim_smooth = "Smoothness",
        lang = "Language", unload = "Unload script", unload_btn = "Unload",
        antiban = "Basic AntiBan (always on)", antiban_desc = "AFK-kick guard, randomized attack timing.",
        errcopy = "Copy error log", errcopied = "Copied", errnone = "No errors yet",
        time_left = "Time left", time_day = "d", expired_msg = "Key expired, script stopped.",
        d_1H = "1 Hour", d_24H = "1 Day", d_1M = "1 Month", d_1Y = "1 Year",
        buy = "BUY", shop_hint = "Reference prices, the game server decides. Purchases go straight to your inventory.",
        c_sword = "Swords", c_gun = "Guns", c_acc = "Accessories", c_skill = "Abilities", c_style = "Fighting styles", c_misc = "Misc",
        buying = "Buying %s...", buy_ok = "Bought %s (-%s)", farm_speed = "Farm fly speed",
        sec_goto = "Fly to player", goto_btn = "Fly to", goto_stop = "Stop", goto_none = "Nobody selected",
        goto_sel = "Selected: %s", sec_extra = "Extras", fpsboost = "FPS boost (less lag)", autobuso = "Auto Armament Haki",
        shop_fly = "Flying to the seller NPC: %s...", shop_nonpc = "Seller NPC for %s not found, trying direct buy...",
        buy_fail = "Could not buy %s: not enough currency or requirement missing",
        st_ready = "Ready", st_off = "AutoFarm off", st_respawn = "Waiting for respawn...",
        st_nomob = "No mobs found, waiting...", st_noweapon = "No weapon in backpack",
        st_flyto = "Flying to: %s", st_fight = "Silent attack: %s %s", st_fastfight = "Fast silent attack: %s %s",
        st_swing = "Normal attack: %s %s", st_probe = "Testing silent attack: %s",
        st_aura_wait = "Waiting for a sample hit: attack once by hand (%s)",
        st_wrongweapon = "Chosen type missing, using %s", st_goquest = "Flying to quest NPC: %s",
        st_questok = "Quest accepted: %s", st_questfail = "Quest not accepted, retrying later...",
        st_island = "Flying to island with: %s", st_nospawn = "No spawn point found: %s",
        st_noquest = "No quest for this level", st_sea = "Warning: not Sea 1",
        st_saber_lv = "Auto Saber needs level 200", st_saber_done = "Saber owned, Auto Saber stopped",
        st_saber_boss = "Saber: fighting Saber Expert", st_saber_plates = "Saber: stepping on the jungle plates",
        st_saber_torch = "Saber: getting the torch", st_saber_burn = "Saber: lighting the desert fire",
        st_saber_quest = "Saber: quest chain (%s)", st_saber_room = "Saber: entering the Saber room",
    },
}
do
    local ORDER = {
        "tab_fam", "tab_move", "tab_esp", "tab_aim", "tab_set", "autofam", "autostat", "stat_which", "stat_Melee", "stat_Sword",
        "stat_Demon", "fast", "skills", "weapon", "w_Melee", "w_Sword", "w_Fruit", "w_Gun", "monster", "all",
        "height", "fly", "flyspeed", "run", "runspeed", "esp_on", "esp_players", "esp_mobs", "esp_box", "esp_name",
        "esp_dist", "esp_hp", "esp_tracer", "esp_chams", "esp_color", "esp_tcolor", "esp_origin", "o_bottom", "o_center", "o_top",
        "aim_on", "aim_part", "p_head", "p_body", "p_feet", "aim_target", "t_players", "t_mobs", "aim_showfov", "aim_fov",
        "aim_fovcolor", "aim_smooth", "lang", "unload", "unload_btn", "antiban", "time_left", "expired_msg",
    }
    local EXTRA = {
        zh = {
            "刷怪", "移动", "透视", "自瞄", "设置", "自动刷怪", "自动加点", "加点到", "格斗", "剑",
            "恶魔果实", "快速攻击", "使用技能 (Z X C V)", "武器", "格斗", "剑", "果实", "枪", "选择怪物(全部=跟随任务)", "全部",
            "悬停高度", "飞行", "飞行速度", "加速跑", "跑步速度", "开启透视", "玩家", "怪物", "方框", "名称",
            "距离", "血条", "射线", "高亮", "透视颜色", "射线颜色", "射线起点", "底部(垂直向上)", "中间", "顶部",
            "自瞄锁定", "瞄准部位", "头部", "身体", "脚部", "目标", "玩家", "怪物", "显示FOV圈", "FOV大小(最大360)",
            "FOV颜色", "平滑度", "语言", "卸载脚本", "卸载", "基础防封(始终开启)", "剩余时间", "密钥已过期,脚本已停止。",
        },
        ja = {
            "ファーム", "移動", "ESP", "エイム", "設定", "オートファーム", "自動ステ振り", "ポイント振り先", "格闘", "剣",
            "悪魔の実", "高速攻撃", "スキル使用 (Z X C V)", "武器", "格闘", "剣", "悪魔の実", "銃", "モンスター選択(すべて=クエスト準拠)", "すべて",
            "ホバー高度", "飛行", "飛行速度", "高速走行", "走行速度", "ESPを有効化", "プレイヤー", "モンスター", "ボックス", "名前",
            "距離", "体力バー", "トレーサー", "ハイライト", "ESPの色", "線の色", "線の起点", "下(真上へ)", "中央", "上",
            "エイムロック", "狙う部位", "頭", "体", "足", "ターゲット", "プレイヤー", "モンスター", "FOVの円を表示", "FOVサイズ(最大360)",
            "FOVの色", "滑らかさ", "言語", "スクリプト終了", "終了", "基本アンチBAN(常時オン)", "残り時間", "キーの期限が切れました。停止します。",
        },
        ko = {
            "파밍", "이동", "ESP", "에임", "설정", "자동 파밍", "자동 스탯", "스탯 투자", "격투", "검",
            "악마의 열매", "빠른 공격", "스킬 사용 (Z X C V)", "무기", "격투", "검", "열매", "총", "몬스터 선택(전체=퀘스트 따라감)", "전체",
            "호버 높이", "비행", "비행 속도", "빠른 달리기", "달리기 속도", "ESP 켜기", "플레이어", "몬스터", "박스", "이름",
            "거리", "체력바", "트레이서", "하이라이트", "ESP 색상", "선 색상", "선 시작점", "아래(수직 위로)", "중앙", "위",
            "에임락", "조준 부위", "머리", "몸", "발", "대상", "플레이어", "몬스터", "FOV 원 표시", "FOV 크기(최대 360)",
            "FOV 색상", "부드러움", "언어", "스크립트 종료", "종료", "기본 안티밴(항상 켜짐)", "남은 시간", "키가 만료되어 스크립트가 중지되었습니다.",
        },
        es = {
            "Farmeo", "Movimiento", "ESP", "Aim", "Ajustes", "AutoFarm (misión + combate)", "Auto puntos", "Sumar puntos a", "Combate", "Espada",
            "Fruta del Diablo", "Ataque rápido", "Usar habilidades (Z X C V)", "Arma", "Combate", "Espada", "Fruta", "Pistola", "Elegir monstruo (Todos = misión)", "Todos",
            "Altura de vuelo", "Volar", "Velocidad de vuelo", "Correr rápido", "Velocidad de carrera", "Activar ESP", "Jugadores", "Monstruos", "Caja", "Nombre",
            "Distancia", "Barra de vida", "Línea", "Resaltado", "Color ESP", "Color de línea", "Origen de línea", "Abajo (recto arriba)", "Centro", "Arriba",
            "Aimlock", "Apuntar a", "Cabeza", "Cuerpo", "Pies", "Objetivo", "Jugadores", "Monstruos", "Mostrar círculo FOV", "Tamaño FOV (máx. 360)",
            "Color del FOV", "Suavidad", "Idioma", "Descargar script", "Descargar", "AntiBan básico (siempre activo)", "Tiempo restante", "La clave expiró, script detenido.",
        },
        pt = {
            "Farm", "Movimento", "ESP", "Mira", "Config.", "AutoFarm (missão + luta)", "Pontos automáticos", "Adicionar pontos em", "Combate", "Espada",
            "Fruta do Demônio", "Ataque rápido", "Usar habilidades (Z X C V)", "Arma", "Combate", "Espada", "Fruta", "Arma de fogo", "Escolher monstro (Todos = missão)", "Todos",
            "Altura de voo", "Voar", "Velocidade de voo", "Correr rápido", "Velocidade de corrida", "Ativar ESP", "Jogadores", "Monstros", "Caixa", "Nome",
            "Distância", "Barra de vida", "Linha", "Destaque", "Cor do ESP", "Cor da linha", "Origem da linha", "Embaixo (reto para cima)", "Centro", "Em cima",
            "Aimlock", "Mirar em", "Cabeça", "Corpo", "Pés", "Alvo", "Jogadores", "Monstros", "Mostrar círculo FOV", "Tamanho do FOV (máx. 360)",
            "Cor do FOV", "Suavidade", "Idioma", "Descarregar script", "Descarregar", "AntiBan básico (sempre ativo)", "Tempo restante", "A chave expirou, script parado.",
        },
        id = {
            "Farming", "Gerakan", "ESP", "Aim", "Pengaturan", "AutoFarm (quest + tarung)", "Poin otomatis", "Tambah poin ke", "Tarung", "Pedang",
            "Buah Iblis", "Serangan cepat", "Pakai skill (Z X C V)", "Senjata", "Tarung", "Pedang", "Buah", "Senjata api", "Pilih monster (Semua = ikut quest)", "Semua",
            "Tinggi melayang", "Terbang", "Kecepatan terbang", "Lari cepat", "Kecepatan lari", "Aktifkan ESP", "Pemain", "Monster", "Kotak", "Nama",
            "Jarak", "Bar darah", "Garis", "Sorotan", "Warna ESP", "Warna garis", "Asal garis", "Bawah (lurus ke atas)", "Tengah", "Atas",
            "Aimlock", "Bidik ke", "Kepala", "Badan", "Kaki", "Target", "Pemain", "Monster", "Tampilkan lingkaran FOV", "Ukuran FOV (maks. 360)",
            "Warna FOV", "Kehalusan", "Bahasa", "Hapus script", "Hapus", "AntiBan dasar (selalu aktif)", "Sisa waktu", "Key kedaluwarsa, script dihentikan.",
        },
    }
    for code, arr in pairs(EXTRA) do
        local t = {}
        for i, key in ipairs(ORDER) do t[key] = arr[i] end
        T[code] = t
    end
end
local lang = "vi"
local function tr(k, ...)
    local s = (T[lang] and T[lang][k]) or T.en[k] or T.vi[k] or k
    if select("#", ...) > 0 then return string.format(s, ...) end
    return s
end

----------------------------------------------------------------
-- TIỆN ÍCH GIAO DIỆN
----------------------------------------------------------------
local conns = {}
local function bind(c) table.insert(conns, c) return c end

local function make(class, props)
    local inst = Instance.new(class)
    local parent = props.Parent
    for k, v in pairs(props) do
        if k ~= "Parent" then inst[k] = v end
    end
    inst.Parent = parent
    return inst
end
local function corner(i, r) return make("UICorner", { CornerRadius = UDim.new(0, r), Parent = i }) end
local function stroke(i, col, th, tp)
    return make("UIStroke", { Color = col, Thickness = th, Transparency = tp or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = i })
end
local function gradient(i, c1, c2, rot)
    return make("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rot or 90, Parent = i })
end
local function tween(i, props, d)
    TweenService:Create(i, TweenInfo.new(d or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local parentGui = (gethui and gethui()) or player:WaitForChild("PlayerGui")
for _, n in ipairs({ "GumballMenu", "GumballKey" }) do
    local o = parentGui:FindFirstChild(n)
    if o then o:Destroy() end
end

----------------------------------------------------------------
-- KEY: kiểm tra chữ ký, máy chủ (1 key = 1 máy), lưu key
----------------------------------------------------------------
local parseKey
do
local B62 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
local function hashStr(s, mult)
    local h = 5381
    for i = 1, #s do h = (h * mult + s:byte(i)) % 4294967296 end
    return h
end
local function sign(body)
    local s = CONFIG.Secret .. body .. CONFIG.Secret
    local out = {}
    for _, h in ipairs({ hashStr(s, 33), hashStr(s, 131) }) do
        for _ = 1, 3 do
            local i = h % 62
            out[#out + 1] = B62:sub(i + 1, i + 1)
            h = math.floor(h / 62)
        end
    end
    return table.concat(out)
end
function parseKey(k)
    local t, r, s = k:match("^GUMBALL%-(%w+)%-(%w%w%w%w)%-(%w%w%w%w%w%w)$")
    if not t or not DURATIONS[t] then return nil end
    if sign("GUMBALL-" .. t .. "-" .. r) ~= s then return nil end
    return t
end
end

local function getHwid()
    local id
    pcall(function() id = game:GetService("RbxAnalyticsService"):GetClientId() end)
    if (not id or id == "") and gethwid then pcall(function() id = gethwid() end) end
    return tostring(id or "unknown")
end
local HWID = getHwid()

local function readFile(path)
    local ok, data = pcall(function()
        if isfile and readfile and isfile(path) then return readfile(path) end
        return nil
    end)
    return ok and data or nil
end
local function writeFile(path, data)
    pcall(function() if writefile then writefile(path, data) end end)
end

-- Chế độ offline: lưu thời điểm kích hoạt trên máy (không khóa được key theo máy)
local records = {}
for line in (readFile(CONFIG.RecordFile) or ""):gmatch("[^\r\n]+") do
    local k, ts = line:match("^(.-),(%d+)$")
    if k then records[k] = tonumber(ts) end
end
local function verifyOffline(key)
    local t = parseKey(key)
    if not t then return false, "bad" end
    local act = records[key] or os.time()
    if os.time() >= act + DURATIONS[t] then return false, "expired" end
    if not records[key] then
        records[key] = act
        local lines = {}
        for k, ts in pairs(records) do lines[#lines + 1] = k .. "," .. ts end
        writeFile(CONFIG.RecordFile, table.concat(lines, "\n"))
    end
    return true, t, act + DURATIONS[t], os.time()
end

local function verifyOnline(key)
    if HWID == "unknown" or #HWID < 8 then return false, "net" end
    local url = string.format("%s/activate?key=%s&hwid=%s", CONFIG.ServerUrl,
        HttpService:UrlEncode(key), HttpService:UrlEncode(HWID))
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if not ok or type(body) ~= "string" then return false, "net" end
    local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok2 or type(data) ~= "table" then return false, "net" end
    if data.ok then return true, data.type, data.expiresAt, data.now end
    return false, data.error or "bad"
end
local function verifyKey(key)
    if CONFIG.ServerUrl ~= "" then return verifyOnline(key) end
    return verifyOffline(key)
end

local authorized, closedKey = false, false
local expiresAt, keyType, timeOffset = 0, "1H", 0
local function accept(key, t, exp, now)
    expiresAt, keyType = exp, t
    timeOffset = (tonumber(now) or os.time()) - os.time()
    writeFile(CONFIG.KeyFile, key)
    authorized = true
end

-- Đã đăng nhập từ trước trên máy này -> vào thẳng, không hỏi key
local savedKey = readFile(CONFIG.KeyFile)
if savedKey then
    savedKey = savedKey:match("^%s*(.-)%s*$")
    local ok, t, exp, now = verifyKey(savedKey)
    if ok then accept(savedKey, t, exp, now) end
end

if not authorized then
    local kgui = make("ScreenGui", { Name = "GumballKey", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = parentGui })
    local f = make("Frame", { Size = UDim2.fromOffset(360, 222), Position = UDim2.new(0.5, -180, 0.5, -111),
        BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = kgui })
    corner(f, 16)
    gradient(f, Color3.fromRGB(30, 12, 18), Color3.fromRGB(8, 8, 11), 90)
    local fs = stroke(f, C.White, 2, 0)
    gradient(fs, C.RedHi, C.RedDark, 45)
    make("Frame", { Size = UDim2.new(1, -40, 0, 2), Position = UDim2.fromOffset(20, 58), BackgroundColor3 = C.Red,
        BorderSizePixel = 0, Parent = f })
    local ttl = make("TextLabel", { Size = UDim2.new(1, -60, 0, 30), Position = UDim2.fromOffset(20, 12), BackgroundTransparency = 1,
        Text = "Gumball", Font = Enum.Font.GothamBlack, TextSize = 24, TextColor3 = C.White,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
    gradient(ttl, C.White, C.RedHi, 0)
    make("TextLabel", { Size = UDim2.new(1, -40, 0, 18), Position = UDim2.fromOffset(20, 36), BackgroundTransparency = 1,
        Text = tr("key_title"), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.Gray,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
    local x = make("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -40, 0, 12),
        BackgroundColor3 = C.Red, Text = "X", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.White, Parent = f })
    corner(x, 8)
    local box = make("TextBox", { Size = UDim2.new(1, -40, 0, 42), Position = UDim2.fromOffset(20, 74),
        BackgroundColor3 = C.Row, Text = savedKey or "", PlaceholderText = tr("key_ph"), PlaceholderColor3 = C.Gray,
        ClearTextOnFocus = false, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = C.White, Parent = f })
    corner(box, 10) stroke(box, C.Red, 1, 0.6)
    local submit = make("TextButton", { Size = UDim2.new(1, -40, 0, 44), Position = UDim2.fromOffset(20, 126),
        BackgroundColor3 = C.White, Text = tr("key_ok"), Font = Enum.Font.GothamBold, TextSize = 16,
        TextColor3 = C.White, Parent = f })
    corner(submit, 10) gradient(submit, C.RedHi, C.RedDark, 90)
    local msg = make("TextLabel", { Size = UDim2.new(1, -40, 0, 34), Position = UDim2.fromOffset(20, 176),
        BackgroundTransparency = 1, Text = (CONFIG.ServerUrl == "") and tr("key_offline") or "",
        Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.Gray, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = f })

    local attempts, lockedUntil, busy = 0, 0, false
    local function trySubmit()
        if busy then return end
        local left = lockedUntil - os.clock()
        if left > 0 then msg.TextColor3 = C.RedHi msg.Text = tr("key_lock", math.ceil(left)) return end
        busy = true
        msg.TextColor3 = C.Gray
        msg.Text = tr("key_check")
        local entered = string.match(box.Text, "^%s*(.-)%s*$")
        local ok, a, b, c = verifyKey(entered)
        if ok then
            accept(entered, a, b, c)
        else
            msg.TextColor3 = C.RedHi
            if a == "expired" then msg.Text = tr("key_expired")
            elseif a == "used" then msg.Text = tr("key_used")
            elseif a == "net" then msg.Text = tr("key_net")
            elseif a == "rate" then msg.Text = tr("key_rate")
            else
                attempts = attempts + 1
                if attempts >= CONFIG.MaxAttempts then
                    attempts = 0
                    lockedUntil = os.clock() + CONFIG.LockSeconds
                    msg.Text = tr("key_lock", CONFIG.LockSeconds)
                else
                    msg.Text = tr("key_bad", CONFIG.MaxAttempts - attempts)
                end
            end
        end
        busy = false
    end
    submit.MouseButton1Click:Connect(trySubmit)
    box.FocusLost:Connect(function(enter) if enter then trySubmit() end end)
    x.MouseButton1Click:Connect(function() closedKey = true end)

    repeat task.wait(0.1) until authorized or closedKey
    kgui:Destroy()
end
if closedKey then return end

----------------------------------------------------------------
-- TRẠNG THÁI (mọi chức năng mặc định TẮT)
----------------------------------------------------------------
local ALL = "__ALL__"
local state = {
    AutoFarm = false, AutoSaber = false, AutoStat = false, StatWhich = "Melee",
    Fast = false, Skills = false, Bring = true, FarmSpeed = 60, FarmStyle = "straight", WeaponIndex = 1,
    SelectedMonster = ALL, Hover = 12,
    Fly = false, FlySpeed = 80, Run = false, RunSpeed = 60,
    ESP = false, ESPPlayers = false, ESPMobs = false, ESPBox = false, ESPName = false, ESPDist = false,
    ESPHp = false, ESPTracer = false, ESPChams = false, ESPOrigin = "bottom",
    FpsBoost = false, AutoBuso = false,
    ESPColor = Color3.fromRGB(255, 60, 60), TracerColor = Color3.fromRGB(255, 255, 255),
    Aim = false, AimPart = "Head", AimTarget = "Players", ShowFov = true, Fov = 120,
    FovColor = Color3.fromRGB(255, 255, 255), Smooth = 0.4,
}
local travelActive, farmPause = false, false
local function farmWanted() return state.AutoFarm or state.AutoSaber end
local function farmOn() return farmWanted() and not farmPause end
local uiSet = {} -- để code đổi trạng thái công tắc trên giao diện (vd: tự tắt Auto Saber khi xong)

local relabel = {}
local statusLabel, statusDot
local statusKey, statusArgs, lastText, lastActive = "st_ready", {}, "", nil
local function refreshStatus()
    if statusLabel then
        lastText = tr(statusKey, table.unpack(statusArgs))
        statusLabel.Text = lastText
    end
end
local function setStatus(key, active, ...)
    statusKey, statusArgs = key, { ... }
    local text = tr(key, ...)
    if text ~= lastText and statusLabel then
        lastText = text
        statusLabel.Text = text
    end
    if active ~= lastActive and statusDot then
        lastActive = active
        statusDot.BackgroundColor3 = active and C.Green or C.Gray
    end
end

----------------------------------------------------------------
-- DỮ LIỆU GAME: QUEST / REMOTE / NPC
----------------------------------------------------------------
local QuestData
pcall(function() QuestData = require(RS:WaitForChild("Quests", 5)) end)

local function timedCall(fn, timeout)
    local done, ok, res = false, false, nil
    task.spawn(function()
        ok, res = pcall(fn)
        done = true
    end)
    local t0 = os.clock()
    while not done and os.clock() - t0 < timeout do task.wait(0.05) end
    if not done then return false, "timeout" end
    return ok, res
end

local CommF
local function getCommF()
    if not CommF then
        local r = RS:FindFirstChild("Remotes")
        CommF = r and r:FindFirstChild("CommF_")
    end
    return CommF
end
local function invoke(...)
    if not getCommF() then return nil end
    local args = table.pack(...)
    local ok, res = timedCall(function() return CommF:InvokeServer(table.unpack(args, 1, args.n)) end, 5)
    return ok and res or nil
end
-- Gọi remote và trả về (ok, kết quả/lỗi) để ghi log
local function rawInvoke(...)
    if not getCommF() then return false, "không thấy CommF_" end
    local args = table.pack(...)
    return timedCall(function() return CommF:InvokeServer(table.unpack(args, 1, args.n)) end, 5)
end

local function dataValue(name)
    local d = player:FindFirstChild("Data")
    local v = d and d:FindFirstChild(name)
    return v and tonumber(v.Value) or 0
end
local function currentLevel()
    local l = dataValue("Level")
    return l > 0 and l or 1
end

-- Quest farm Sea 1 đã biết (tọa độ NPC chỉ là GỢI Ý theo trí nhớ, luôn đối chiếu với NPC thật trong game)
local QUEST_HINTS = {
    ["BanditQuest1:1"] = Vector3.new(1059.37, 15.45, 1550.42),
    ["JungleQuest:1"] = Vector3.new(-1598.09, 35.55, 153.38),
    ["JungleQuest:2"] = Vector3.new(-1598.09, 35.55, 153.38),
    ["BuggyQuest1:1"] = Vector3.new(-1141.07, 4.10, 3831.55),
    ["BuggyQuest1:2"] = Vector3.new(-1141.07, 4.10, 3831.55),
    ["DesertQuest:1"] = Vector3.new(894.49, 5.14, 4392.43),
    ["DesertQuest:2"] = Vector3.new(894.49, 5.14, 4392.43),
    ["SnowQuest:1"] = Vector3.new(1389.74, 87.27, -1298.91),
    ["SnowQuest:2"] = Vector3.new(1389.74, 87.27, -1298.91),
    ["MarineQuest2:1"] = Vector3.new(-5039.59, 24.20, 4167.29),
    ["SkyQuest:1"] = Vector3.new(-4839.53, 716.37, -2619.44),
    ["SkyQuest:2"] = Vector3.new(-4839.53, 716.37, -2619.44),
    ["PrisonerQuest:1"] = Vector3.new(5308.93, 1.66, 475.12),
    ["PrisonerQuest:2"] = Vector3.new(5308.93, 1.66, 475.12),
    ["ColosseumQuest:1"] = Vector3.new(-1580.05, 6.35, -2986.48),
    ["ColosseumQuest:2"] = Vector3.new(-1580.05, 6.35, -2986.48),
    ["MagmaQuest:1"] = Vector3.new(-5313.37, 10.95, 8515.29),
    ["MagmaQuest:2"] = Vector3.new(-5313.37, 10.95, 8515.29),
    ["FishmanQuest:1"] = Vector3.new(61122.65, 18.50, 1568.16),
    ["FishmanQuest:2"] = Vector3.new(61122.65, 18.50, 1568.16),
    ["SkyExp1Quest:1"] = Vector3.new(-4721.89, 843.87, -1949.97),
    ["SkyExp1Quest:2"] = Vector3.new(-4721.89, 843.87, -1949.97),
    ["SkyExp2Quest:1"] = Vector3.new(-7859.10, 5544.19, -381.48),
    ["SkyExp2Quest:2"] = Vector3.new(-7859.10, 5544.19, -381.48),
    ["FountainQuest:1"] = Vector3.new(5259.82, 37.35, 4050.03),
}

-- Chọn quest đúng cấp: LevelReq cao nhất mà vẫn đủ cấp (ưu tiên danh sách quest farm đã biết)
local function pickQuest()
    if not QuestData then return nil end
    local lvl, bestKnown, bestAny = currentLevel(), nil, nil
    for qName, list in pairs(QuestData) do
        if type(list) == "table" then
            for idx, q in pairs(list) do
                if type(q) == "table" and type(q.LevelReq) == "number" and type(q.Task) == "table"
                    and q.LevelReq <= lvl and q.LevelReq <= CONFIG.MaxQuestLevel then
                    local mob, count
                    for m, c in pairs(q.Task) do mob, count = m, c end
                    if mob and type(count) == "number" and count > 1 then
                        local cand = { name = qName, index = idx, req = q.LevelReq, mob = mob, count = count }
                        if QUEST_HINTS[qName .. ":" .. tostring(idx)] and (not bestKnown or q.LevelReq > bestKnown.req) then
                            bestKnown = cand
                        end
                        if not bestAny or q.LevelReq > bestAny.req then bestAny = cand end
                    end
                end
            end
        end
    end
    return bestKnown or bestAny
end

local function findSpawnPos(mob, from)
    local origin = Workspace:FindFirstChild("_WorldOrigin")
    local spawns = origin and origin:FindFirstChild("EnemySpawns")
    if not spawns then return nil end
    local best, bestD = nil, math.huge
    for _, s in ipairs(spawns:GetChildren()) do
        if s:IsA("BasePart") and string.find(s.Name, mob, 1, true) then
            local d = (s.Position - from).Magnitude
            if d < bestD then best, bestD = s.Position, d end
        end
    end
    return best
end

local function allNpcs()
    local list = {}
    local folder = Workspace:FindFirstChild("NPCs")
    if folder then
        for _, m in ipairs(folder:GetChildren()) do
            local part
            if m:IsA("BasePart") then
                part = m
            elseif m:IsA("Model") then
                part = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart", true)
            end
            if part then list[#list + 1] = { name = m.Name, pos = part.Position, real = true } end
        end
    end
    return list
end

-- Danh sách điểm cần ghé để nhận quest, tối đa 3:
-- 1) NPC thật gần tọa độ gợi ý  2) tọa độ gợi ý  3) NPC gần khu quái nhất
local function questNpcList(key, anchor)
    local out, npcs = {}, allNpcs()
    local hint = QUEST_HINTS[key]
    if hint then
        local bestN, bd = nil, 250
        for _, n in ipairs(npcs) do
            local d = (n.pos - hint).Magnitude
            if d < bd then bestN, bd = n, d end
        end
        out[#out + 1] = bestN or { name = "hint", pos = hint, real = false }
    end
    if anchor then
        table.sort(npcs, function(a, b) return (a.pos - anchor).Magnitude < (b.pos - anchor).Magnitude end)
        for i = 1, #npcs do
            if #out >= 3 then break end
            local dup = false
            for _, o in ipairs(out) do if (o.pos - npcs[i].pos).Magnitude < 30 then dup = true end end
            if not dup then out[#out + 1] = npcs[i] end
        end
    end
    return out
end

local autoStatToken = 0
local function startAutoStat()
    autoStatToken = autoStatToken + 1
    local my = autoStatToken
    task.spawn(guard(function()
        while state.AutoStat and my == autoStatToken do
            local d = player:FindFirstChild("Data")
            local p = d and d:FindFirstChild("Points")
            if p and p.Value > 0 then invoke("AddPoint", state.StatWhich, p.Value) end
            task.wait(1.5)
        end
    end))
end

----------------------------------------------------------------
-- TRẠNG THÁI QUEST: lấy từ chính sự kiện QuestUpdate của game (nguồn tin cậy duy nhất)
-- Dạng dữ liệu (đã thấy trong log): { InternalQuestName, Info = { Task = { [quái] = số }, LevelReq, ... },
--                                      Progress = { [quái] = số đã đánh }, UID, TimeStarted }
----------------------------------------------------------------
local QE = { t = 0, data = nil, done = {}, ctxSeen = {} }
do
    local r = RS:FindFirstChild("Remotes")
    local ev = r and r:FindFirstChild("QuestUpdate")
    if ev and ev:IsA("RemoteEvent") then
        bind(ev.OnClientEvent:Connect(function(a, b)
            QE.t = os.clock()
            local ctx = ""
            if type(b) == "table" and b.Context ~= nil then ctx = tostring(b.Context) end
            local lc = ctx:lower()
            if type(a) == "table" then QE.data = a end
            if not QE.ctxSeen[lc] then
                QE.ctxSeen[lc] = true
                dbg("QuestUpdate context '" .. ctx .. "': " .. describeArgs(table.pack(a, b)))
            end
            if lc:find("complet", 1, true) or lc:find("finish", 1, true) or lc:find("done", 1, true) then
                if type(a) == "table" and a.UID then QE.done[a.UID] = true end
            elseif lc:find("abandon", 1, true) or lc:find("cancel", 1, true) or lc:find("remov", 1, true)
                or lc:find("clear", 1, true) or lc:find("reset", 1, true) then
                QE.data = nil
            end
        end))
    end
end

-- Quest đang làm (nil nếu chưa có). done = đã đủ số lượng.
local function activeQuest()
    local d = QE.data
    if type(d) ~= "table" or type(d.Info) ~= "table" or type(d.Info.Task) ~= "table" then return nil end
    local uid = d.UID
    local mob, need, prog
    local allDone = true
    for m, c in pairs(d.Info.Task) do
        local p = (type(d.Progress) == "table" and tonumber(d.Progress[m])) or 0
        if type(c) == "number" and p < c then
            allDone = false
            mob, need, prog = m, c, p
            break
        end
        mob, need, prog = mob or m, need or c, prog or p
    end
    if not mob then return nil end
    local finished = allDone or (uid ~= nil and QE.done[uid] == true)
    return { name = tostring(d.InternalQuestName or d.Info.Name or "?"), mob = mob, need = need, prog = prog,
        uid = uid, done = finished }
end

----------------------------------------------------------------
-- QUÁI + VŨ KHÍ + ĐÁNH
----------------------------------------------------------------
local function getSearchRoot() return Workspace:FindFirstChild(CONFIG.MonsterFolder) or Workspace end

local function isAliveMonster(m)
    if not m:IsA("Model") or Players:GetPlayerFromCharacter(m) then return false end
    local h, r = m:FindFirstChildOfClass("Humanoid"), m:FindFirstChild("HumanoidRootPart")
    return h ~= nil and r ~= nil and h.Health > 0
end

local function listMonsterNames()
    local seen, names = {}, {}
    for _, o in ipairs(getSearchRoot():GetChildren()) do
        if isAliveMonster(o) and not seen[o.Name] then
            seen[o.Name] = true
            names[#names + 1] = o.Name
        end
    end
    table.sort(names)
    table.insert(names, 1, ALL)
    return names
end

local blacklist = {}
local function findNearestTarget(root, mob)
    local best, bd = nil, math.huge
    for _, o in ipairs(getSearchRoot():GetChildren()) do
        if isAliveMonster(o) and (mob == nil or o.Name == mob) and not (blacklist[o] and blacklist[o] > os.clock()) then
            local d = (o.HumanoidRootPart.Position - root.Position).Magnitude
            if d < bd then best, bd = o, d end
        end
    end
    return best
end

local function equipWeapon()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil, false end
    local wanted = CONFIG.Weapons[state.WeaponIndex].tip
    local held = char:FindFirstChildOfClass("Tool")
    if held and held.ToolTip == wanted then return held, true end
    local bp = player:FindFirstChildOfClass("Backpack")
    local firstAny
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                if t.ToolTip == wanted then hum:EquipTool(t) return t, true end
                firstAny = firstAny or t
            end
        end
    end
    if held then return held, false end
    if firstAny then hum:EquipTool(firstAny) return firstAny, false end
    return nil, false
end

local menuMain
local lastMenuInput = 0

local SKILL_KEYS = { Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V }
local function useSkills()
    if not VIM or os.clock() - lastMenuInput < 0.9 then return end
    for _, k in ipairs(SKILL_KEYS) do
        pcall(function() VIM:SendKeyEvent(true, k, false, game) end)
        task.wait(0.04)
        pcall(function() VIM:SendKeyEvent(false, k, false, game) end)
        task.wait(0.04)
    end
end

----------------------------------------------------------------
-- ĐÁNH ẨN (AURA)
-- Cách làm: ghi lại đúng lệnh RegisterAttack/RegisterHit mà game gửi khi có đòn đánh THẬT trúng quái,
-- rồi gửi lại cho tất cả quái xung quanh. Có 5 kiểu gửi, tự thử từng kiểu và chỉ giữ kiểu làm quái mất máu.
-- Nếu cả 5 kiểu đều không gây sát thương thì tự quay về đánh thường (và lấy mẫu đòn mới), thử lại sau vài giây.
----------------------------------------------------------------
local auraMode = nil -- nil = chưa thử, true = có sát thương, false = không có sát thương
local auraFailStamp, nextProbeAt = -1, 0

-- Tìm quái (không phải người chơi) nằm trong danh sách tham số
local function targetModelIn(v, depth)
    local t = typeof(v)
    if t == "Instance" then
        local mychar = player.Character
        if mychar and (v == mychar or v:IsDescendantOf(mychar)) then return nil end
        local m
        if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then m = v
        elseif v:IsA("BasePart") and v.Parent and v.Parent:IsA("Model") and v.Parent:FindFirstChildOfClass("Humanoid") then
            m = v.Parent
        end
        if m and not Players:GetPlayerFromCharacter(m) then return m end
    elseif t == "table" and depth < 4 then
        for _, x in pairs(v) do
            local m = targetModelIn(x, depth + 1)
            if m then return m end
        end
    end
    return nil
end

local Cap = genv.GumballCap3
if not Cap then
    Cap = { atk = nil, hit = nil, hitPos = nil, stamp = 0, hooked = false, pending = {}, seen = 0 }
    genv.GumballCap3 = Cap
end
do
    local mod = RS:FindFirstChild("Modules")
    local net = mod and mod:FindFirstChild("Net")
    if net then
        Cap.reAttack = net:WaitForChild("RE/RegisterAttack", 5)
        Cap.reHit = net:WaitForChild("RE/RegisterHit", 5)
    end
    if not (Cap.reAttack and Cap.reHit) then dbg("Không thấy RE/RegisterAttack hoặc RE/RegisterHit trong Modules.Net") end
end
-- Xử lý mẫu đòn (chạy ngoài hook, không làm hỏng lời gọi gốc của game)
Cap.record = function(self, packed)
    if self == Cap.reHit then
        Cap.seen = Cap.seen + 1
        local m
        for i = 1, packed.n do
            m = targetModelIn(packed[i], 0)
            if m then break end
        end
        if Cap.seen <= 4 then
            dbg("RegisterHit #" .. Cap.seen .. (m and (" (trúng " .. m.Name .. ")") or " (không có quái)") .. ": " .. describeArgs(packed))
        end
        if m then -- bỏ qua các lần vung trượt (không có quái)
            Cap.hit = packed
            Cap.synth, Cap.strIdx = false, nil
            for i = 2, packed.n do
                if type(packed[i]) == "string" then Cap.strIdx = i break end
            end
            local r = m:FindFirstChild("HumanoidRootPart")
            Cap.hitPos = r and r.Position
            Cap.stamp = Cap.stamp + 1
        end
    elseif self == Cap.reAttack then
        Cap.atk = packed
        if not Cap.atkLogged then
            Cap.atkLogged = true
            dbg("Mẫu RegisterAttack: " .. describeArgs(packed))
        end
    end
end
if not Cap.hooked and hookmetamethod and getnamecallmethod and Cap.reAttack and Cap.reHit then
    local okHook = pcall(function()
        local old
        old = hookmetamethod(game, "__namecall", (newcclosure or function(f) return f end)(function(self, ...)
            -- Trong hook chỉ lưu lại tham số, không gọi hàm của Instance (tránh làm sai lời gọi gốc)
            local method = getnamecallmethod()
            if (self == Cap.reHit or self == Cap.reAttack) and (method == "FireServer" or method == "fireServer")
                and not (checkcaller and checkcaller()) then
                local q = Cap.pending
                if #q > 20 then table.remove(q, 1) end
                q[#q + 1] = { self, table.pack(...) }
            end
            return old(self, ...)
        end))
    end)
    Cap.hooked = okHook
    dbg("Hook ghi mẫu đòn đánh: " .. tostring(okHook))
end
bind(RunService.Heartbeat:Connect(guard(function()
    local q = Cap.pending
    if #q > 0 then
        Cap.pending = {}
        for i = 1, #q do Cap.record(q[i][1], q[i][2]) end
    end
end)))

local auraReady, aliveMobs, auraTick, auraProbe, auraSynth
do
local function retarget(v, model, part, depth, delta, base)
    local t = typeof(v)
    if t == "Instance" then
        local mychar = player.Character
        if mychar and (v == mychar or v:IsDescendantOf(mychar)) then return v end
        if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then return model end
        if v:IsA("BasePart") and v.Parent and v.Parent:IsA("Model") and v.Parent:FindFirstChildOfClass("Humanoid") then
            return model:FindFirstChild(v.Name) or part
        end
        return v
    elseif t == "table" and depth < 4 then
        local out = {}
        for k, x in pairs(v) do out[k] = retarget(x, model, part, depth + 1, delta, base) end
        return out
    elseif t == "Vector3" and delta and base and (v - base).Magnitude < 40 then
        return v + delta -- vị trí trúng đòn đi theo quái mới
    elseif t == "CFrame" and delta and base and (v.Position - base).Magnitude < 40 then
        return v + delta
    end
    return v
end

function auraReady() return Cap.hit ~= nil and Cap.reHit ~= nil end

local rehash = false
local function guid8() return (HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 8)) end
-- Mẫu tự dựng khi game chưa sinh mẫu thật (không cần click): kiểu 1 = (bộ phận, {{quái, bộ phận}}),
-- kiểu 2 = thêm tham số mã 8 ký tự ngẫu nhiên. Chỉ dùng nếu thử ra sát thương thật.
function auraSynth(model, kind)
    local part = model:FindFirstChild("HumanoidRootPart")
    if not part then return false end
    local head = model:FindFirstChild("Head") or part
    local list = { { model, part } }
    if kind == 1 then
        Cap.hit, Cap.strIdx = table.pack(head, list), nil
    else
        Cap.hit, Cap.strIdx = table.pack(head, list, {}, guid8()), 4
    end
    Cap.hitPos, Cap.synth = part.Position, true
    return true
end

-- Danh sách quái còn sống, làm mới 5 lần/giây (đỡ quét Workspace liên tục)
do
    local cache, stamp = {}, 0
    aliveMobs = function()
        if os.clock() - stamp > 0.2 then
            stamp = os.clock()
            local list = {}
            for _, o in ipairs(getSearchRoot():GetChildren()) do
                if isAliveMonster(o) then list[#list + 1] = o end
            end
            cache = list
        end
        return cache
    end
end

-- Mẫu có dạng "danh sách cặp {quái, bộ phận}" (kiểu game đang dùng) thì gom tất cả quái vào MỘT lệnh trúng đòn
local function isPairList(v)
    if type(v) ~= "table" then return false end
    local first = v[1]
    if type(first) ~= "table" then return false end
    local n = 0
    for _, x in pairs(first) do
        n = n + 1
        if typeof(x) ~= "Instance" then return false end
    end
    return n > 0
end
local function partOf(model, like)
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if like and like:IsA("BasePart") then return model:FindFirstChild(like.Name) or hrp end
    return hrp
end
local function buildBatch(mobs)
    local sample = Cap.hit
    local out, used = {}, false
    for i = 1, sample.n do
        local v = sample[i]
        if typeof(v) == "Instance" and v:IsA("BasePart") and not (player.Character and v:IsDescendantOf(player.Character)) then
            out[i] = partOf(mobs[1], v)
        elseif isPairList(v) then
            used = true
            local list, first = {}, v[1]
            for _, m in ipairs(mobs) do
                local pair = {}
                for k, x in pairs(first) do
                    if x:IsA("Model") then pair[k] = m
                    elseif x:IsA("BasePart") then pair[k] = partOf(m, x)
                    else pair[k] = x end
                end
                list[#list + 1] = pair
            end
            out[i] = list
        else
            out[i] = v
        end
    end
    return out, used
end

local function fireOne(model)
    local part = model:FindFirstChild("HumanoidRootPart")
    if not part or not Cap.hit then return end
    local delta = Cap.hitPos and (part.Position - Cap.hitPos) or nil
    local out = {}
    for i = 1, Cap.hit.n do out[i] = retarget(Cap.hit[i], model, part, 0, delta, Cap.hitPos) end
    if rehash and Cap.strIdx then out[Cap.strIdx] = guid8() end
    pcall(function() Cap.reHit:FireServer(table.unpack(out, 1, Cap.hit.n)) end)
end

local function nearMobs(root)
    local list = {}
    for _, o in ipairs(aliveMobs()) do
        local r = o.Parent and o:FindFirstChild("HumanoidRootPart")
        local h = r and o:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 then
            local d = (r.Position - root.Position).Magnitude
            if d <= CONFIG.AuraRange then list[#list + 1] = { m = o, d = d } end
        end
    end
    table.sort(list, function(a, b) return a.d < b.d end)
    local out = {}
    for i = 1, math.min(#list, CONFIG.AuraMax) do out[i] = list[i].m end
    return out
end

local VARIANTS = {
    { atk = true, batch = true, gap = 0 },
    { atk = false, batch = true, gap = 0 },
    { atk = true, batch = false, gap = 0 },
    { atk = true, batch = true, gap = 0.03 },
    { atk = false, batch = false, gap = 0 },
    { atk = true, batch = true, gap = 0, rehash = true },
    { atk = false, batch = true, gap = 0, rehash = true },
}
local auraVariant = 1
function auraTick(root)
    if not auraReady() then return end
    local mobs = nearMobs(root)
    if #mobs == 0 then return end
    local v = VARIANTS[auraVariant]
    rehash = (v.rehash == true) or (Cap.synth == true)
    if v.atk and Cap.reAttack then
        local a = Cap.atk or table.pack(0.5, 1)
        pcall(function() Cap.reAttack:FireServer(table.unpack(a, 1, a.n)) end)
    end
    if v.gap > 0 then task.wait(v.gap) end
    if v.batch then
        local out, used = buildBatch(mobs)
        if rehash and Cap.strIdx then out[Cap.strIdx] = guid8() end
        if used then
            pcall(function() Cap.reHit:FireServer(table.unpack(out, 1, Cap.hit.n)) end)
            return
        end
    end
    for _, m in ipairs(mobs) do fireOne(m) end
end

-- Thử lần lượt các kiểu gửi, kiểu nào làm quái mất máu thì dùng
function auraProbe(tHum, root)
    local hp0 = tHum.Health
    for v = 1, #VARIANTS do
        auraVariant = v
        for _ = 1, 4 do
            if not auraReady() or tHum.Health <= 0 then break end
            auraTick(root)
            task.wait(0.12)
        end
        if tHum.Health < hp0 then
            dbg(string.format("Đánh ẩn kiểu %d: CÓ sát thương (máu %d -> %d)", v, math.floor(hp0), math.floor(tHum.Health)))
            return true
        end
        if tHum.Health <= 0 then return false end
    end
    dbg(string.format("Đánh ẩn: KHÔNG sát thương ở cả %d kiểu (máu %d). Mẫu: %s", #VARIANTS, math.floor(hp0),
        Cap.hit and describeArgs(Cap.hit) or "(trống)"))
    return false
end

end

----------------------------------------------------------------
-- DI CHUYỂN: AUTOFAM, BAY, CHẠY NHANH (1 vòng Heartbeat, nghỉ khi không dùng)
----------------------------------------------------------------
local noclipConn, noclipParts, lastScan = nil, {}, 0
local function setNoclip(on)
    if on and not noclipConn then
        noclipConn = RunService.Stepped:Connect(guard(function()
            local c = player.Character
            if not c then return end
            if os.clock() - lastScan > 1 then
                lastScan = os.clock()
                noclipParts = {}
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then noclipParts[#noclipParts + 1] = p end
                end
            end
            for i = 1, #noclipParts do noclipParts[i].CanCollide = false end
        end))
    elseif not on and noclipConn then
        noclipConn:Disconnect()
        noclipConn, noclipParts = nil, {}
    end
end

local hoverTargetRoot, hoverTargetHum, hoverPoint = nil, nil, nil
local lastMobPos = nil
local inRange, pointReached, wasActive = false, false, false

local function cleanupMove()
    inRange, pointReached = false, false
    setNoclip(false)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        for _, n in ipairs({ "GumballHover", "GumballFly" }) do
            local o = root:FindFirstChild(n)
            if o then o:Destroy() end
        end
    end
end

local autoHeight, noLowerUntil, lastDmgT = nil, 0, 0 -- độ cao tự nâng khi bị quái đánh
local orbitAngle = 0
local function uprightAt(pos, root, faceTo)
    local look = faceTo and (faceTo - pos) or root.CFrame.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
    return CFrame.lookAt(pos, pos + flat.Unit)
end

local function heartbeat(dt)
    local farming = farmOn() or travelActive
    local active = farming or state.Fly or state.Run
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not active or not root or not hum then
        if wasActive then wasActive = false cleanupMove() end
        return
    end
    wasActive = true
    setNoclip(farming or state.Fly)
    local dt2 = math.min(dt, 1 / 30) -- tránh bước nhảy lớn khi máy giật

    -- AutoFam: đi xa bằng vận tốc (mượt, ít bị máy chủ kéo lại), tới gần thì khóa vị trí.
    -- Luôn đứng thẳng. Quái chết thì GIỮ NGUYÊN vị trí (không bám theo xác).
    local hbv = root:FindFirstChild("GumballHover")
    if farming then
        if not hbv then
            hbv = make("BodyVelocity", { Name = "GumballHover", MaxForce = Vector3.new(math.huge, math.huge, math.huge),
                Velocity = Vector3.zero, Parent = root })
        end
        local goal, face
        local alive = hoverTargetHum ~= nil and hoverTargetHum.Health > 0 and hoverTargetRoot ~= nil and hoverTargetRoot.Parent ~= nil
        if hoverTargetRoot then
            if alive then
                lastMobPos = hoverTargetRoot.Position
                local h = Cap.low and 3 or (autoHeight or state.Hover)
                if state.FarmStyle == "orbit" then
                    orbitAngle = (orbitAngle + dt2 * 1.4) % (math.pi * 2)
                    goal = lastMobPos + Vector3.new(math.cos(orbitAngle) * 9, h, math.sin(orbitAngle) * 9)
                    face = lastMobPos
                else
                    goal = lastMobPos + Vector3.new(0, h, 0)
                end
            else
                goal = root.Position
            end
        elseif hoverPoint then
            goal = hoverPoint
        end
        if goal then
            local pos = root.Position
            local off = goal - pos
            local dist = off.Magnitude
            hbv.Velocity = Vector3.zero
            if dist > 0.05 then
                -- tốc độ đều, giảm dần khi tới gần => bay mượt, không giật
                local spd = math.min(travelActive and state.FlySpeed or state.FarmSpeed, dist * 8)
                pos = pos + off.Unit * math.min(dist, spd * math.min(dt, 1 / 20))
            end
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = uprightAt(pos, root, face)
            local arrived = dist <= 5
            if hoverTargetRoot then
                inRange, pointReached = (arrived and alive), false
            else
                inRange, pointReached = false, arrived
            end
        else
            hbv.Velocity = Vector3.zero
            inRange, pointReached = false, false
        end
    elseif hbv then
        hbv:Destroy()
    end

    -- Chạy nhanh: cộng thêm quãng đường theo hướng đi (không phụ thuộc WalkSpeed của game)
    if state.Run and not farming and hum.MoveDirection.Magnitude > 0 then
        local extra = state.RunSpeed - 16
        if extra > 0 then root.CFrame = root.CFrame + hum.MoveDirection * extra * dt end
    end

    -- Bay tự do
    local fbv = root:FindFirstChild("GumballFly")
    if state.Fly and not farming then
        if not fbv then
            fbv = make("BodyVelocity", { Name = "GumballFly", MaxForce = Vector3.new(math.huge, math.huge, math.huge),
                Velocity = Vector3.zero, Parent = root })
        end
        local cam = Workspace.CurrentCamera
        local dir = hum.MoveDirection
        local v = dir * state.FlySpeed
        if cam and dir.Magnitude > 0 then
            local look = cam.CFrame.LookVector
            local flat = Vector3.new(look.X, 0, look.Z)
            if flat.Magnitude > 0 then
                v = v + Vector3.new(0, look.Y * dir:Dot(flat.Unit) * state.FlySpeed, 0)
            end
        end
        if UIS:IsKeyDown(Enum.KeyCode.Space) or hum.Jump then v = v + Vector3.new(0, state.FlySpeed, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then v = v - Vector3.new(0, state.FlySpeed, 0) end
        fbv.Velocity = fbv.Velocity:Lerp(v, math.min(1, dt * 8))
    elseif fbv then
        fbv:Destroy()
    end
end
bind(RunService.Heartbeat:Connect(guard(heartbeat)))

----------------------------------------------------------------
-- VÒNG LẶP AUTOFAM: nhận quest -> bay tới quái -> đánh. KHÔNG nhận quest mới khi quest cũ chưa đủ.
----------------------------------------------------------------
local farmToken = 0
local questRetryAt = 0
local npcCache = {}
local remoteAnywhere = nil
local lastBring = 0
local questFails = 0
local stopFarm

local function bringMobs(target)
    if os.clock() - lastBring < 0.25 then return end
    lastBring = os.clock()
    pcall(function() if sethiddenproperty then sethiddenproperty(player, "SimulationRadius", math.huge) end end)
    local tr0 = target:FindFirstChild("HumanoidRootPart")
    if not tr0 then return end
    local pos = tr0.Position
    local others = {}
    for _, o in ipairs(aliveMobs()) do
        if o ~= target and o.Name == target.Name then
            local r = o:FindFirstChild("HumanoidRootPart")
            if r then
                local d = (r.Position - pos).Magnitude
                if d < 450 then others[#others + 1] = { r = r, d = d } end
            end
        end
    end
    table.sort(others, function(a, b) return a.d < b.d end)
    for i = 1, math.min(#others, CONFIG.BringMax - 1) do
        local r = others[i].r
        pcall(function() r.CFrame = CFrame.new(pos) r.AssemblyLinearVelocity = Vector3.zero end)
    end
end

local function flyTo(pos, my, root)
    hoverTargetRoot, hoverTargetHum, hoverPoint = nil, nil, pos
    pointReached = false
    local t0 = os.clock()
    local limit = (pos - root.Position).Magnitude / math.max(state.FarmSpeed, 10) + 15
    while farmOn() and my == farmToken and not pointReached and os.clock() - t0 < limit do
        task.wait(0.05)
    end
    return pointReached
end

local function posFromAny(v, depth)
    local t = typeof(v)
    if t == "Vector3" then return v end
    if t == "CFrame" then return v.Position end
    if t == "Instance" then
        if v:IsA("BasePart") then return v.Position end
        if v:IsA("Model") then return v:GetPivot().Position end
    elseif t == "string" then
        for _, n in ipairs(allNpcs()) do
            if n.name == v or string.find(n.name, v, 1, true) then return n.pos end
        end
    elseif t == "table" and depth < 3 then
        for _, x in pairs(v) do
            local pp = posFromAny(x, depth + 1)
            if pp then return pp end
        end
    end
    return nil
end

-- Hỏi chính máy chủ game: NPC nhận quest tốt nhất cho cấp hiện tại ở đâu
local function bestQuestNpcPos()
    local r = RS:FindFirstChild("Remotes")
    local f = r and r:FindFirstChild("GetBestQuestNPC")
    if not f or not f:IsA("RemoteFunction") then return nil end
    local ok, res = timedCall(function() return f:InvokeServer() end, 4)
    dbg("GetBestQuestNPC: ok=" .. tostring(ok) .. " -> " .. (ok and describe(res, 0) or tostring(res)))
    if ok and res ~= nil then return posFromAny(res, 0) end
    return nil
end

-- Gửi StartQuest rồi chờ game báo lại bằng QuestUpdate. Kết quả trả về của remote KHÔNG đáng tin
-- (game trả 0 cả khi quest đã nằm sẵn trong người), nên chỉ tin QuestUpdate.
local function tryStart(q, key, oldUID)
    local t0 = os.clock()
    local ok, res = rawInvoke("StartQuest", q.name, q.index)
    dbg(string.format("StartQuest %s: ok=%s kết quả=%s", key, tostring(ok), describe(res, 0)))
    local deadline = os.clock() + 2
    while os.clock() < deadline do
        local aq = activeQuest()
        if aq and aq.name == q.name and QE.t >= t0 - 0.05 and not (oldUID ~= nil and aq.uid == oldUID) then
            return true
        end
        task.wait(0.15)
    end
    return false
end

local function takeQuest(q, my, root)
    local key = q.name .. ":" .. tostring(q.index)
    local aq = activeQuest()
    if aq and not aq.done then return true end -- đang có quest chưa xong: TUYỆT ĐỐI không nhận quest mới
    local oldUID = aq and aq.uid

    if remoteAnywhere ~= false then
        if tryStart(q, key, oldUID) then
            remoteAnywhere, questFails = true, 0
            dbg("Nhận quest tại chỗ OK: " .. key)
            setStatus("st_questok", true, q.name)
            return true
        end
        remoteAnywhere = false
        dbg("Không nhận được tại chỗ, bay tới NPC")
    end

    local anchor = findSpawnPos(q.mob, root.Position)
    if not anchor then
        local m = findNearestTarget(root, q.mob)
        anchor = m and m.HumanoidRootPart.Position
    end
    local cands = {}
    local bestPos = bestQuestNpcPos()
    if bestPos then cands[#cands + 1] = { name = "GetBestQuestNPC", pos = bestPos, real = true } end
    if npcCache[key] then cands[#cands + 1] = { name = "cache", pos = npcCache[key], real = true } end
    for _, c in ipairs(questNpcList(key, anchor)) do cands[#cands + 1] = c end

    local realTried, lastPos = 0, nil
    for i = 1, math.min(#cands, 6) do
        if not (farmOn() and my == farmToken) then return false end
        local c = cands[i]
        if not (lastPos and (c.pos - lastPos).Magnitude < 25) then
            lastPos = c.pos
            dbg(string.format("%s: bay tới '%s' (%d,%d,%d)", key, c.name, c.pos.X, c.pos.Y, c.pos.Z))
            setStatus("st_goquest", true, q.name)
            if flyTo(c.pos + Vector3.new(0, 3, 0), my, root) then
                task.wait(0.4)
                if tryStart(q, key, oldUID) or tryStart(q, key, oldUID) then
                    npcCache[key] = c.pos
                    questFails = 0
                    dbg(key .. ": nhận quest OK")
                    setStatus("st_questok", true, q.name)
                    return true
                end
                if c.real then
                    realTried = realTried + 1
                    if realTried >= 3 then break end
                end
            else
                dbg(key .. ": không bay tới được điểm này")
            end
        end
    end
    questFails = questFails + 1
    dbg(string.format("%s: chưa nhận được quest (lần %d)", key, questFails))
    return false
end

-- Đánh một con quái cho tới khi chết. isBoss = true thì không bỏ qua quái kẹt.
local function fightLoop(my, target, isBoss)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local tHum = target:FindFirstChildOfClass("Humanoid")
    local tRoot = target:FindFirstChild("HumanoidRootPart")
    if not (root and hum and tHum and tRoot) then return end
    hoverPoint = nil
    lastMobPos = tRoot.Position
    hoverTargetRoot, hoverTargetHum = tRoot, tHum
    local tool
    local lastEquip, lastSkill, lastProg, prog, lastProbeMsg = 0, 0, 0, "", 0
    local lastHp, lastHpT, outSince = tHum.Health, os.clock(), os.clock()
    local auraDmgT, lastAuraHp = os.clock(), tHum.Health
    local lastMyHp, bootT, waitSince = hum.Health, 0, os.clock()
    while farmOn() and my == farmToken and tHum.Health > 0 and tRoot.Parent and hum.Health > 0 do
        Cap.low = (auraMode ~= true) and not isBoss -- chưa có đánh ẩn chạy được thì hạ thấp để đòn thật trúng và lấy mẫu
        -- chống treo: quái không mất máu 20 giây khi đã ở trong tầm, hoặc không bay tới được 25 giây thì bỏ qua
        if tHum.Health < lastHp then lastHpT = os.clock() end
        lastHp = tHum.Health
        if not inRange then lastHpT = os.clock() end
        if inRange then outSince = os.clock() end
        if not isBoss and (os.clock() - lastHpT > 20 or os.clock() - outSince > 25) then
            blacklist[target] = os.clock() + 30
            dbg("Bỏ qua quái kẹt: " .. target.Name)
            break
        end
        -- bay ở độ cao sát nhất mà quái không đánh tới: bị đánh thì nâng lên, yên 30 giây thì hạ dần
        if hum.Health < lastMyHp - 0.5 then
            autoHeight = math.min((autoHeight or state.Hover) + 3, 45)
            noLowerUntil, lastDmgT = os.clock() + 60, os.clock()
            dbg("Bị quái đánh, nâng độ cao lên " .. autoHeight)
        elseif autoHeight and autoHeight > state.Hover and os.clock() > noLowerUntil and os.clock() - lastDmgT > 30 then
            autoHeight = math.max(state.Hover, autoHeight - 1)
            lastDmgT = os.clock()
        end
        lastMyHp = hum.Health

        if not tool or tool.Parent ~= player.Character or os.clock() - lastEquip > 0.6 then
            tool = equipWeapon()
            lastEquip = os.clock()
        end
        if os.clock() - lastProg > 0.7 then
            lastProg = os.clock()
            local aq = (not isBoss) and activeQuest() or nil
            prog = aq and (aq.name .. " " .. aq.prog .. "/" .. aq.need) or ""
            -- quest đã đủ số: đi nhận quest mới ngay (nếu tới lượt thử lại)
            if aq and aq.done and state.SelectedMonster == ALL and state.AutoFarm and os.clock() >= questRetryAt then
                dbg("Quest đủ số lượng: " .. aq.name)
                break
            end
        end

        if not tool then
            setStatus("st_noweapon", false)
        elseif not inRange then
            setStatus("st_flyto", true, target.Name)
        else
            if state.Bring and not isBoss then bringMobs(target) end
            if auraMode == false and os.clock() >= nextProbeAt then auraMode = nil end
            local usedAura = false
            if auraReady() and auraMode ~= false then
                if auraMode == nil then
                    setStatus("st_probe", true, target.Name)
                    auraMode = auraProbe(tHum, root)
                    auraDmgT, lastAuraHp = os.clock(), tHum.Health
                    if not auraMode then
                        auraFailStamp = Cap.stamp
                        nextProbeAt = os.clock() + CONFIG.AuraProbeGap
                    end
                end
                if auraMode then
                    usedAura = true
                    waitSince = os.clock()
                    setStatus(state.Fast and "st_fastfight" or "st_fight", true, target.Name, prog)
                    auraTick(root)
                    if state.Fast then auraTick(root) end
                    if tHum.Health < lastAuraHp then lastAuraHp, auraDmgT = tHum.Health, os.clock() end
                    if os.clock() - auraDmgT > 3 then
                        auraMode, auraFailStamp = false, Cap.stamp
                        nextProbeAt = os.clock() + CONFIG.AuraProbeGap
                        if Cap.synth then Cap.hit, Cap.strIdx, Cap.synth = nil, nil, false end
                        dbg("Đánh ẩn ngừng gây sát thương, sẽ thử lại sau vài giây")
                    end
                end
            end
            if not usedAura then
                setStatus("st_aura_wait", false, target.Name)
                if os.clock() - bootT > 0.6 then
                    bootT = os.clock()
                    pcall(function() tool:Activate() end) -- mở đòn thật (không click) để game sinh mẫu
                end
                -- chưa có mẫu thật: thử mẫu tự dựng, kiểu nào ra sát thương thì dùng
                Cap.nextSynth = Cap.nextSynth or 0
                if not auraReady() and os.clock() - waitSince > 2 and os.clock() >= Cap.nextSynth then
                    Cap.nextSynth = os.clock() + 20
                    for kind = 1, 2 do
                        if tHum.Health <= 0 then break end
                        auraSynth(target, kind)
                        if auraProbe(tHum, root) then
                            auraMode = true
                            auraDmgT, lastAuraHp = os.clock(), tHum.Health
                            dbg("Mẫu tự dựng kiểu " .. kind .. " CÓ sát thương")
                            break
                        end
                        Cap.hit, Cap.strIdx, Cap.synth = nil, nil, false
                    end
                end
            end
            if state.Skills and os.clock() - lastSkill > 0.7 then
                lastSkill = os.clock()
                task.spawn(useSkills)
            end
        end
        task.wait(auraMode and (state.Fast and 0.02 or 0.045) or 0.1)
    end
    inRange = false
    Cap.low = false
end

local function farmStep(my)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then
        hoverTargetRoot, hoverTargetHum, hoverPoint = nil, nil, nil
        setStatus("st_respawn", false)
        task.wait(1)
        return
    end

    local wanted = nil
    if state.SelectedMonster ~= ALL then
        wanted = state.SelectedMonster
    else
        local aq = activeQuest()
        if not aq or aq.done then
            local q = pickQuest()
            if q then
                wanted = q.mob
                if os.clock() >= questRetryAt then
                    if takeQuest(q, my, root) then
                        aq = activeQuest()
                    else
                        questRetryAt = os.clock() + math.min(4 * questFails, 25)
                        setStatus("st_questfail", false)
                    end
                end
            else
                setStatus("st_noquest", false)
            end
        end
        if aq and not aq.done then wanted = aq.mob end -- quest chưa xong thì chỉ đánh đúng quái của quest đó
    end
    if not (farmOn() and my == farmToken) then return end

    local target = findNearestTarget(root, wanted)
    if not target then
        hoverTargetRoot, hoverTargetHum = nil, nil
        local sp = wanted and findSpawnPos(wanted, root.Position)
        if sp then
            QE.noSpawn = nil
            hoverPoint = sp + Vector3.new(0, state.Hover, 0)
            setStatus("st_island", true, wanted)
        else
            hoverPoint = nil
            if wanted then
                setStatus("st_nospawn", false, wanted)
                QE.noSpawn = QE.noSpawn or os.clock()
                if os.clock() - QE.noSpawn > 6 and state.SelectedMonster == ALL and activeQuest() then
                    dbg("Quest cũ/lạ (không có điểm sinh quái), hủy để nhận quest mới")
                    invoke("AbandonQuest")
                    QE.data, QE.noSpawn, questRetryAt = nil, nil, 0
                end
            else
                setStatus("st_nomob", false)
            end
        end
        task.wait(0.4)
        return
    end
    QE.noSpawn = nil
    fightLoop(my, target, false)
end

----------------------------------------------------------------
-- AUTO SABER (BETA): cần cấp 200. Khúc đánh Saber Expert chắc chắn chạy; các bước giải đố dựng theo
-- quy trình quest mà tôi nhớ nên CHƯA kiểm chứng trong game. Mỗi bước đều ghi log để sửa tiếp.
----------------------------------------------------------------
local saberStep
do
local SABER = {
    plates = Vector3.new(-1612.56, 36.98, 148.72),
    torch = Vector3.new(-1610.01, 11.50, 164.00),
    burn = Vector3.new(1114.61, 5.05, 4350.23),
    rich = Vector3.new(-910.98, 13.75, 4078.15),
    mobLeader = Vector3.new(-2848.59, 7.43, 5342.44),
    room = Vector3.new(-1401.85, 29.98, 8.82),
}
local function mapPath(...)
    local cur = Workspace
    for _, n in ipairs({ ... }) do
        cur = cur and cur:FindFirstChild(n)
    end
    return cur
end
local function posOf(o)
    if not o then return nil end
    if o:IsA("BasePart") then return o.Position end
    if o:IsA("Model") then return o:GetPivot().Position end
    local b = o:FindFirstChildWhichIsA("BasePart", true)
    return b and b.Position
end
local function hasToolQuick(name)
    local c = player.Character
    if c and c:FindFirstChild(name) then return true end
    local bp = player:FindFirstChildOfClass("Backpack")
    return bp ~= nil and bp:FindFirstChild(name) ~= nil
end
local invCache = { t = -100, names = {} }
local function ownsItem(name)
    if hasToolQuick(name) then return true end
    if os.clock() - invCache.t > 10 then
        invCache.t = os.clock()
        invCache.names = {}
        local inv = invoke("getInventory")
        if type(inv) == "table" then
            for _, it in pairs(inv) do
                if type(it) == "table" and it.Name then invCache.names[it.Name] = true end
            end
        end
    end
    return invCache.names[name] == true
end
local function touchPart(part, root)
    if firetouchinterest and part and root then
        pcall(function()
            firetouchinterest(root, part, 0)
            task.wait()
            firetouchinterest(root, part, 1)
        end)
    end
end
local function pressPromptsNear(pos, radius)
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
            local pp = d.Parent and posOf(d.Parent)
            if pp and (pp - pos).Magnitude <= radius then
                pcall(function()
                    if d:IsA("ProximityPrompt") then
                        if fireproximityprompt then fireproximityprompt(d) end
                    elseif fireclickdetector then
                        fireclickdetector(d)
                    end
                end)
            end
        end
    end
end

function saberStep(my)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then
        hoverTargetRoot, hoverTargetHum, hoverPoint = nil, nil, nil
        setStatus("st_respawn", false)
        task.wait(1)
        return
    end
    if currentLevel() < 200 then
        setStatus("st_saber_lv", false)
        task.wait(1.5)
        return
    end
    if ownsItem("Saber") then
        setStatus("st_saber_done", false)
        dbg("Đã có Saber, dừng Auto Saber")
        if uiSet.AutoSaber then uiSet.AutoSaber(false) else state.AutoSaber = false end
        if not farmWanted() then stopFarm() end
        return
    end

    local boss = findNearestTarget(root, "Saber Expert")
    if boss then
        setStatus("st_saber_boss", true)
        fightLoop(my, boss, true)
        return
    end

    local map = Workspace:FindFirstChild("Map")
    local plates = map and map:FindFirstChild("QuestPlates", true)
    local door = plates and plates:FindFirstChild("Door")
    local finalM = map and map:FindFirstChild("Final", true)
    local final = finalM and (finalM:FindFirstChild("Part") or (finalM:IsA("BasePart") and finalM or nil))
    local burnM = map and map:FindFirstChild("Burn", true)
    local burn = burnM and (burnM:FindFirstChild("Part") or (burnM:IsA("BasePart") and burnM or nil))
    if not Cap.saberScan then
        Cap.saberScan = true
        dbg(string.format("Saber quét map: plates=%s door=%s final=%s burn=%s", tostring(plates), tostring(door), tostring(final), tostring(burn)))
    end

    if final and final.Transparency ~= 0 then
        setStatus("st_saber_room", true)
        flyTo(SABER.room + Vector3.new(0, 3, 0), my, root)
        task.wait(1)
        return
    end

    if door and door.Transparency == 0 then
        setStatus("st_saber_plates", true)
        dbg("Saber: giẫm 6 bàn đạp")
        local platesPos = posOf(plates) or SABER.plates
        if (root.Position - platesPos).Magnitude > 120 then
            flyTo(platesPos + Vector3.new(0, 4, 0), my, root)
        end
        for i = 1, 6 do
            if not (farmOn() and my == farmToken) then return end
            local plate = plates and plates:FindFirstChild("Plate" .. i)
            local btn = plate and (plate:FindFirstChild("Button") or plate)
            local pos = btn and posOf(btn)
            if pos then
                flyTo(pos + Vector3.new(0, 2, 0), my, root)
                touchPart(btn:IsA("BasePart") and btn or nil, root)
                task.wait(0.6)
            else
                dbg("Saber: không thấy Plate" .. i)
            end
        end
        return
    end

    if burn and burn.Transparency == 0 then
        if hasToolQuick("Torch") then
            setStatus("st_saber_burn", true)
            local c = player.Character
            local t = (c and c:FindFirstChild("Torch")) or player:FindFirstChildOfClass("Backpack"):FindFirstChild("Torch")
            if t and hum then pcall(function() hum:EquipTool(t) end) end
            flyTo(posOf(burn) + Vector3.new(0, 3, 0), my, root)
            touchPart(burn, root)
            task.wait(1)
        else
            setStatus("st_saber_torch", true)
            flyTo(SABER.torch + Vector3.new(0, 3, 0), my, root)
            pressPromptsNear(SABER.torch, 40)
            task.wait(1.5)
        end
        return
    end

    -- Chuỗi nhiệm vụ Sick Man / Rich Son / Mob Leader / Relic
    local okS, sick = rawInvoke("ProQuestProgress", "SickMan")
    dbg("Saber SickMan -> ok=" .. tostring(okS) .. " " .. describe(sick, 0))
    if okS and sick == 0 then
        setStatus("st_saber_room", true)
        flyTo(SABER.room + Vector3.new(0, 3, 0), my, root)
        local okP, resP = rawInvoke("ProQuestProgress", "PlaceRelic")
        dbg("Saber PlaceRelic -> ok=" .. tostring(okP) .. " " .. describe(resP, 0))
        task.wait(1.5)
        return
    end
    if not hasToolQuick("Cup") then
        local okC, resC = rawInvoke("ProQuestProgress", "GetCup")
        dbg("Saber GetCup -> ok=" .. tostring(okC) .. " " .. describe(resC, 0))
    else
        local cc = player.Character
        local cup = (cc and cc:FindFirstChild("Cup")) or player:FindFirstChildOfClass("Backpack"):FindFirstChild("Cup")
        local okF, resF = rawInvoke("ProQuestProgress", "FillCup", cup)
        dbg("Saber FillCup -> ok=" .. tostring(okF) .. " " .. describe(resF, 0))
    end
    local okR, rich = rawInvoke("ProQuestProgress", "RichSon")
    dbg("Saber RichSon -> ok=" .. tostring(okR) .. " " .. describe(rich, 0))
    setStatus("st_saber_quest", true, tostring(rich))
    if rich == nil then
        local richPos = SABER.rich
        for _, n in ipairs(allNpcs()) do
            if n.name:lower():find("rich", 1, true) then richPos = n.pos break end
        end
        flyTo(richPos + Vector3.new(0, 3, 0), my, root)
        pressPromptsNear(richPos, 40)
        local ok2, r2 = rawInvoke("ProQuestProgress", "RichSon")
        dbg("Saber RichSon (tại NPC) -> ok=" .. tostring(ok2) .. " " .. describe(r2, 0))
    elseif rich == 0 then
        local leader = findNearestTarget(root, "Mob Leader")
        if leader then
            fightLoop(my, leader, true)
        else
            flyTo(SABER.mobLeader + Vector3.new(0, 12, 0), my, root)
        end
    else
        flyTo(SABER.room + Vector3.new(0, 3, 0), my, root)
        local okP, resP = rawInvoke("ProQuestProgress", "PlaceRelic")
        dbg("Saber PlaceRelic -> ok=" .. tostring(okP) .. " " .. describe(resP, 0))
    end
    task.wait(1.5)
end

end

local function startFarm()
    farmToken = farmToken + 1
    local my = farmToken
    task.spawn(function()
        while farmWanted() and my == farmToken do
            if farmPause then
                task.wait(0.3)
            else
                local ok, e = pcall(function()
                    if state.AutoSaber then saberStep(my) else farmStep(my) end
                end)
                if not ok then logErr(e) task.wait(0.5) end
                task.wait()
            end
        end
    end)
end

function stopFarm()
    Cap.low = false
    farmToken = farmToken + 1
    hoverTargetRoot, hoverTargetHum, hoverPoint = nil, nil, nil
    inRange, pointReached = false, false
end

-- AntiBan cơ bản: chống kick AFK
bind(player.Idled:Connect(guard(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
end)))

----------------------------------------------------------------
-- GIAO DIỆN CHÍNH (đỏ + đen)
----------------------------------------------------------------
local gui = make("ScreenGui", { Name = "GumballMenu", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = parentGui })

-- Lớp ESP và vòng FOV nằm dưới menu
local espLayer = make("Frame", { Name = "EspLayer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    BorderSizePixel = 0, Parent = gui })
local fovCircle = make("Frame", { Name = "Fov", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(state.Fov * 2, state.Fov * 2), BackgroundTransparency = 1, Visible = false, Parent = gui })
corner(fovCircle, 1000)
local fovStroke = make("UIStroke", { Color = state.FovColor, Thickness = 1.5, Parent = fovCircle })

local MW, MH = 580, 430
local main = make("Frame", { Name = "Main", Size = UDim2.fromOffset(MW, MH),
    Position = UDim2.new(0.5, -MW / 2, 0.5, -MH / 2 - 20), BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = gui })
corner(main, 18)
gradient(main, Color3.fromRGB(28, 12, 17), Color3.fromRGB(8, 8, 11), 90)
local mainStroke = stroke(main, C.White, 2, 0)
local mainStrokeGrad = gradient(mainStroke, C.RedHi, C.RedDark, 0)
menuMain = main
-- viền chạy màu nhẹ nhàng
bind(RunService.RenderStepped:Connect(function(dt)
    if main.Visible then mainStrokeGrad.Rotation = (mainStrokeGrad.Rotation + dt * 60) % 360 end
end))

-- Bảng đen đếm ngược thời gian key (đi theo menu)
local timerLabel
do
    local timerBar = make("Frame", { Name = "Timer", Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 1, 8),
        BackgroundColor3 = C.Black, BorderSizePixel = 0, Parent = main })
    corner(timerBar, 12) stroke(timerBar, C.Red, 1.5, 0.35)
    timerLabel = make("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
        Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.Green, Parent = timerBar })
end

local titleBar = make("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = main })
corner(titleBar, 18)
gradient(titleBar, Color3.fromRGB(96, 10, 20), Color3.fromRGB(14, 14, 18), 0)
make("Frame", { Size = UDim2.new(1, -28, 0, 2), Position = UDim2.new(0, 14, 1, -2), BackgroundColor3 = C.Red,
    BorderSizePixel = 0, Parent = titleBar })
do
    local logo = make("Frame", { Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(14, 9), BackgroundColor3 = C.White,
        BorderSizePixel = 0, Parent = titleBar })
    corner(logo, 17) gradient(logo, C.RedHi, C.RedDark, 90) stroke(logo, C.White, 1.5, 0.55)
    make("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "G", Font = Enum.Font.GothamBlack,
        TextSize = 20, TextColor3 = C.White, Parent = logo })
end
do
    local name = make("TextLabel", { Size = UDim2.new(0, 200, 1, 0), Position = UDim2.fromOffset(58, 0), BackgroundTransparency = 1,
        Text = "Gumball", Font = Enum.Font.GothamBlack, TextSize = 24, TextColor3 = C.White,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = titleBar })
    gradient(name, C.White, C.RedHi, 0)
end

local function titleButton(text, ox, color)
    local b = make("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, ox, 0, 11),
        BackgroundColor3 = color, Text = text, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.White,
        AutoButtonColor = false, Parent = titleBar })
    corner(b, 9)
    b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = C.RedHi }, 0.1) end)
    b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = color }, 0.1) end)
    return b
end
local closeBtn = titleButton("X", -42, C.Red)
local miniBtn = titleButton("-", -78, C.Off)

local body = make("Frame", { Size = UDim2.new(1, -20, 1, -64), Position = UDim2.fromOffset(10, 58),
    BackgroundTransparency = 1, Parent = main })
local sidebar = make("Frame", { Size = UDim2.new(0, 112, 1, 0), BackgroundColor3 = C.Panel, BorderSizePixel = 0, Parent = body })
corner(sidebar, 14)
stroke(sidebar, C.RedDark, 1, 0.55)
make("UIListLayout", { Padding = UDim.new(0, 6), Parent = sidebar })
make("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7), Parent = sidebar })
do
    local keyCard = make("Frame", { Position = UDim2.new(0, 7, 1, -52), Size = UDim2.fromOffset(98, 44), BackgroundColor3 = C.Row,
        BorderSizePixel = 0, ZIndex = 3, Parent = body })
    corner(keyCard, 10) stroke(keyCard, C.Red, 1, 0.5)
    local keyCardLbl = make("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Text = tr("d_" .. keyType), Font = Enum.Font.GothamBlack, TextSize = 15, TextColor3 = C.RedHi, ZIndex = 4, Parent = keyCard })
    table.insert(relabel, function() keyCardLbl.Text = tr("d_" .. keyType) end)
end
local content = make("Frame", { Size = UDim2.new(1, -122, 1, 0), Position = UDim2.fromOffset(122, 0),
    BackgroundTransparency = 1, Parent = body })

-- Kéo thả + khóa cuộn khi đang kéo thanh trượt
local activeDrag, activeInput, lockedScroll
local dragTarget, dragPos = nil, nil
bind(RunService.RenderStepped:Connect(function()
    if dragTarget and dragPos then dragTarget.Position = dragPos end
end))
local function endDrag()
    activeDrag, activeInput = nil, nil
    if dragTarget and dragPos then dragTarget.Position = dragPos end
    dragTarget = nil
    if lockedScroll then lockedScroll.ScrollingEnabled = true lockedScroll = nil end
end
bind(UIS.InputChanged:Connect(guard(function(i)
    if not activeDrag or not activeInput then return end
    local at = activeInput.UserInputType
    if (at == Enum.UserInputType.Touch and i.UserInputType == Enum.UserInputType.Touch)
        or (at == Enum.UserInputType.MouseButton1 and i.UserInputType == Enum.UserInputType.MouseMovement) then
        lastMenuInput = os.clock()
        activeDrag(i.Position)
    end
end)))
bind(UIS.InputEnded:Connect(guard(function(i)
    if activeInput and i == activeInput then endDrag() end
end)))
-- Chỉ nhận chuyển động liên tục của đúng ngón tay đang kéo (bỏ qua ngón khác như cần di chuyển)
local function trackDrag(input, handler)
    local lastP = input.Position
    local touch = input.UserInputType == Enum.UserInputType.Touch
    return function(p)
        if touch and (p - lastP).Magnitude > 200 then return end
        lastP = p
        handler(p)
    end
end
local function makeDraggable(handle, target, onClick)
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local startIn, startPos, moved = input.Position, target.Position, false
            local mine = trackDrag(input, function(p)
                local d = p - startIn
                if d.Magnitude > 8 and not moved then
                    moved = true
                    target:SetAttribute("placed", true) -- nhớ vị trí người dùng đã đặt
                end
                if moved then
                    dragTarget, dragPos = target, UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                end
            end)
            activeDrag, activeInput = mine, input
            local c
            c = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    c:Disconnect()
                    if activeDrag == mine then endDrag() end
                    if not moved and onClick then onClick() end
                end
            end)
        end
    end)
end

local tabs = {}
local function selectTab(name)
    for n, t in pairs(tabs) do
        local on = (n == name)
        t.page.Visible = on
        tween(t.btn, { BackgroundColor3 = on and C.Red or C.Row }, 0.12)
        t.btn.TextColor3 = on and C.White or C.Gray
    end
end
local function addTab(name, key)
    local btn = make("TextButton", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.Row, Text = tr(key),
        Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.Gray, AutoButtonColor = false, Parent = sidebar })
    corner(btn, 10)
    table.insert(relabel, function() btn.Text = tr(key) end)
    local page = make("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = C.Red, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = content })
    make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
    make("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 6), Parent = page })
    tabs[name] = { btn = btn, page = page }
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return page
end

local nextOrder
do
    local orders = {}
    nextOrder = function(page)
        orders[page] = (orders[page] or 0) + 1
        return orders[page]
    end
end
local function row(page, h)
    local f = make("Frame", { Size = UDim2.new(1, 0, 0, h or 44), BackgroundColor3 = C.White, BorderSizePixel = 0,
        LayoutOrder = nextOrder(page), Parent = page })
    corner(f, 12)
    gradient(f, C.RowHi, C.Row, 0)
    stroke(f, C.RedDark, 1, 0.6)
    local accent = make("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 3, 0.55, 0), BackgroundColor3 = C.Red, BorderSizePixel = 0, Parent = f })
    corner(accent, 2)
    return f
end
local function section(page, key)
    local l = make("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = tr(key):upper(),
        Font = Enum.Font.GothamBlack, TextSize = 11, TextColor3 = C.RedHi, TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = nextOrder(page), Parent = page })
    table.insert(relabel, function() l.Text = tr(key):upper() end)
    return l
end
local function L(parent, key, x, y, w, h, size)
    local l = make("TextLabel", { Size = UDim2.new(1, w, 0, h), Position = UDim2.fromOffset(x, y), BackgroundTransparency = 1,
        Text = tr(key), Font = Enum.Font.GothamMedium, TextSize = size or 14, TextColor3 = C.White,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = parent })
    table.insert(relabel, function() l.Text = tr(key) end)
    return l
end

-- Nút có nền chuyển màu (chữ không bị gradient làm tối)
local function gbtn(parent, size, pos, text, c1, c2, ts)
    local bg = make("Frame", { Size = size, Position = pos, BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = parent })
    corner(bg, 9)
    gradient(bg, c1, c2, 90)
    local b = make("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = text,
        Font = Enum.Font.GothamBold, TextSize = ts or 12, TextColor3 = C.White, AutoButtonColor = false, Parent = bg })
    b.MouseEnter:Connect(function() tween(bg, { BackgroundColor3 = Color3.fromRGB(255, 215, 215) }, 0.1) end)
    b.MouseLeave:Connect(function() tween(bg, { BackgroundColor3 = C.White }, 0.1) end)
    return b, bg
end

local function toggle(page, key, stateKey, cb)
    local f = row(page, 44)
    L(f, key, 14, 0, -64, 44, 13)
    local box = make("Frame", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -44, 0.5, -14),
        BackgroundColor3 = C.Off, BorderSizePixel = 0, Parent = f })
    corner(box, 8)
    local bs = stroke(box, C.RedHi, 1.5, 0.35)
    -- dấu tick vẽ bằng 2 nét xoay
    local tick = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = box })
    local arm1 = make("Frame", { Size = UDim2.fromOffset(3, 8), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.34, 0.6), Rotation = -42, BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = tick })
    corner(arm1, 2)
    local arm2 = make("Frame", { Size = UDim2.fromOffset(3, 15), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.58, 0.47), Rotation = 40, BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = tick })
    corner(arm2, 2)
    local btn = make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = f })
    local function paint(on)
        tick.Visible = on
        tween(box, { BackgroundColor3 = on and C.Red or C.Off }, 0.1)
        bs.Transparency = on and 0 or 0.35
    end
    paint(state[stateKey])
    uiSet[stateKey] = function(on)
        state[stateKey] = on
        paint(on)
    end
    btn.MouseButton1Click:Connect(function()
        state[stateKey] = not state[stateKey]
        paint(state[stateKey])
        if cb then guard(cb)(state[stateKey]) end
    end)
end

local function cycle(page, key, stateKey, options, cb)
    local f = row(page, 44)
    L(f, key, 14, 0, -170, 44, 13)
    local idx = 1
    for i, o in ipairs(options) do if o.v == state[stateKey] then idx = i end end
    local b = gbtn(f, UDim2.fromOffset(150, 28), UDim2.new(1, -162, 0.5, -14), tr(options[idx].k), C.RedHi, C.RedDark, 12)
    table.insert(relabel, function() b.Text = tr(options[idx].k) end)
    b.MouseButton1Click:Connect(function()
        idx = (idx % #options) + 1
        state[stateKey] = options[idx].v
        b.Text = tr(options[idx].k)
        if cb then guard(cb)(options[idx].v) end
    end)
end

local function bar(parent, y, min, max, init, dec, cb)
    local track = make("Frame", { Size = UDim2.new(1, -28, 0, 8), Position = UDim2.fromOffset(14, y),
        BackgroundColor3 = C.Off, BorderSizePixel = 0, Parent = parent })
    corner(track, 4)
    local fill = make("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = track })
    corner(fill, 4)
    gradient(fill, C.RedDark, C.RedHi, 0)
    local knob = make("Frame", { Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = C.White, BorderSizePixel = 0, Parent = track })
    corner(knob, 8)
    local hit = make("TextButton", { Size = UDim2.new(1, 0, 0, 28), AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0), BackgroundTransparency = 1, Text = "", Parent = track })
    local mult = 10 ^ dec
    local sf = parent:FindFirstAncestorOfClass("ScrollingFrame")
    local function setAlpha(a)
        a = math.clamp(a, 0, 1)
        local v = math.floor((min + (max - min) * a) * mult + 0.5) / mult
        local aa = (v - min) / (max - min)
        fill.Size = UDim2.new(aa, 0, 1, 0)
        knob.Position = UDim2.new(aa, 0, 0.5, 0)
        return v
    end
    setAlpha((init - min) / (max - min))
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if sf then sf.ScrollingEnabled = false lockedScroll = sf end
            local mineBar = trackDrag(input, function(p)
                cb(setAlpha((p.X - track.AbsolutePosition.X) / track.AbsoluteSize.X))
            end)
            activeDrag, activeInput = mineBar, input
            local c
            c = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    c:Disconnect()
                    if activeDrag == mineBar then endDrag() end
                end
            end)
            mineBar(input.Position)
        end
    end)
end

local function slider(page, key, stateKey, min, max, dec)
    local f = row(page, 60)
    L(f, key, 14, 8, -90, 20, 13)
    local val = make("TextLabel", { Size = UDim2.fromOffset(70, 20), Position = UDim2.new(1, -84, 0, 8),
        BackgroundTransparency = 1, Text = tostring(state[stateKey]), Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = C.RedHi, TextXAlignment = Enum.TextXAlignment.Right, Parent = f })
    bar(f, 42, min, max, state[stateKey], dec, function(v)
        state[stateKey] = v
        val.Text = tostring(v)
    end)
end

local function colorPicker(page, key, stateKey)
    local f = row(page, 118)
    L(f, key, 14, 8, -80, 20, 13)
    local sw = make("Frame", { Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -54, 0, 8),
        BackgroundColor3 = state[stateKey], BorderSizePixel = 0, Parent = f })
    corner(sw, 6) stroke(sw, C.White, 1, 0.3)
    local col = state[stateKey]
    local r, g, b = math.floor(col.R * 255 + 0.5), math.floor(col.G * 255 + 0.5), math.floor(col.B * 255 + 0.5)
    local function apply()
        local c3 = Color3.fromRGB(r, g, b)
        state[stateKey] = c3
        sw.BackgroundColor3 = c3
    end
    bar(f, 46, 0, 255, r, 0, function(v) r = v apply() end)
    bar(f, 72, 0, 255, g, 0, function(v) g = v apply() end)
    bar(f, 98, 0, 255, b, 0, function(v) b = v apply() end)
end

----------------------------------------------------------------
-- TAB FAM
----------------------------------------------------------------
local pFam = addTab("fam", "tab_fam")
section(pFam, "sec_auto")
toggle(pFam, "autofam", "AutoFarm", function(on)
    if on then
        auraMode, autoHeight = nil, nil
        questRetryAt, questFails, remoteAnywhere = 0, 0, nil
        startFarm()
    else
        if farmWanted() then startFarm() else stopFarm() end
        setStatus("st_off", false)
    end
end)
toggle(pFam, "autostat", "AutoStat", function(on) if on then startAutoStat() end end)
cycle(pFam, "stat_which", "StatWhich", {
    { v = "Melee", k = "stat_Melee" }, { v = "Sword", k = "stat_Sword" }, { v = "Demon Fruit", k = "stat_Demon" } })
section(pFam, "sec_fight")
toggle(pFam, "fast", "Fast")
toggle(pFam, "skills", "Skills")
cycle(pFam, "farm_style", "FarmStyle", {
    { v = "straight", k = "style_straight" }, { v = "orbit", k = "style_orbit" } })
toggle(pFam, "bring", "Bring")
cycle(pFam, "weapon", "WeaponIndex", {
    { v = 1, k = "w_Melee" }, { v = 2, k = "w_Sword" }, { v = 3, k = "w_Fruit" }, { v = 4, k = "w_Gun" } },
    function() Cap.hit, Cap.atk, auraMode = nil, nil, nil end)

do
    local f = row(pFam, 44)
    L(f, "monster", 14, 0, -170, 44, 12)
    local b = gbtn(f, UDim2.fromOffset(150, 28), UDim2.new(1, -162, 0.5, -14), tr("all"), C.RedHi, C.RedDark, 12)
    local function show() b.Text = (state.SelectedMonster == ALL) and tr("all") or state.SelectedMonster end
    table.insert(relabel, show)
    b.MouseButton1Click:Connect(function()
        local names = listMonsterNames()
        local nextIdx = 1
        for i, n in ipairs(names) do if n == state.SelectedMonster then nextIdx = (i % #names) + 1 end end
        state.SelectedMonster = names[nextIdx]
        show()
    end)
end
slider(pFam, "height", "Hover", 6, 40, 0)
slider(pFam, "farm_speed", "FarmSpeed", 30, 300, 0)

section(pFam, "sec_saber")
toggle(pFam, "autosaber", "AutoSaber", function(on)
    if on then
        auraMode, autoHeight = nil, nil
        questRetryAt, questFails, remoteAnywhere = 0, 0, nil
        startFarm()
    else
        if farmWanted() then startFarm() else stopFarm() end
        setStatus("st_off", false)
    end
end)

do
    local f = row(pFam, 40)
    f.LayoutOrder = -1 -- trạng thái nằm trên cùng
    statusDot = make("Frame", { Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 14, 0.5, -5),
        BackgroundColor3 = C.Gray, BorderSizePixel = 0, Parent = f })
    corner(statusDot, 5)
    statusLabel = make("TextLabel", { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(32, 0),
        BackgroundTransparency = 1, Text = tr("st_ready"), Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.White,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f })
    lastText = statusLabel.Text
    table.insert(relabel, refreshStatus)
end

----------------------------------------------------------------
-- TAB DI CHUYỂN
----------------------------------------------------------------
local pMove = addTab("move", "tab_move")
toggle(pMove, "fly", "Fly")
slider(pMove, "flyspeed", "FlySpeed", 20, 500, 0)
toggle(pMove, "run", "Run")
slider(pMove, "runspeed", "RunSpeed", 16, 300, 0)

----------------------------------------------------------------
-- BAY TỚI NGƯỜI CHƠI: chọn tên trong danh sách người trên server rồi bấm Bay tới
----------------------------------------------------------------
do
    local selected = nil
    local flightToken = 0
    section(pMove, "sec_goto")
    local f = row(pMove, 178)
    local selLabel = make("TextLabel", { Size = UDim2.new(1, -28, 0, 18), Position = UDim2.fromOffset(14, 6),
        BackgroundTransparency = 1, Text = tr("goto_none"), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.Gold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
    local list = make("ScrollingFrame", { Size = UDim2.new(1, -28, 0, 100), Position = UDim2.fromOffset(14, 28),
        BackgroundColor3 = C.Panel, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Red,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = f })
    corner(list, 8)
    make("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
    make("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingLeft = UDim.new(0, 3), Parent = list })
    local buttons = {}
    local function paintSel()
        for name, b in pairs(buttons) do b.BackgroundColor3 = (name == selected) and C.Red or C.Off end
        selLabel.Text = selected and tr("goto_sel", selected) or tr("goto_none")
    end
    table.insert(relabel, paintSel)
    local function rebuild()
        for _, b in pairs(buttons) do b:Destroy() end
        buttons = {}
        local n = 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                n = n + 1
                local label = (p.DisplayName ~= p.Name) and (p.DisplayName .. " (@" .. p.Name .. ")") or p.Name
                local b = make("TextButton", { Size = UDim2.new(1, -9, 0, 26), LayoutOrder = n, BackgroundColor3 = C.Off,
                    Text = label, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.White,
                    AutoButtonColor = false, Parent = list })
                corner(b, 6)
                buttons[p.Name] = b
                local pname = p.Name
                b.MouseButton1Click:Connect(function() selected = pname paintSel() end)
            end
        end
        if selected and not buttons[selected] then selected = nil end
        paintSel()
    end
    rebuild()
    bind(Players.PlayerAdded:Connect(function() task.wait(0.3) guard(rebuild)() end))
    bind(Players.PlayerRemoving:Connect(function() task.delay(0.3, guard(rebuild)) end))

    local goBtn = gbtn(f, UDim2.new(0.5, -20, 0, 34), UDim2.fromOffset(14, 136), tr("goto_btn"), C.RedHi, C.RedDark, 13)
    local stopBtn = gbtn(f, UDim2.new(0.5, -20, 0, 34), UDim2.new(0.5, 6, 0, 136), tr("goto_stop"), C.Off, Color3.fromRGB(46, 46, 56), 13)
    table.insert(relabel, function() goBtn.Text = tr("goto_btn") stopBtn.Text = tr("goto_stop") end)

    local function endFlight()
        hoverPoint = nil
        travelActive = false
        farmPause = false
        if not farmWanted() then cleanupMove() end
    end
    goBtn.MouseButton1Click:Connect(function()
        local p = selected and Players:FindFirstChild(selected)
        if not p then return end
        flightToken = flightToken + 1
        local my = flightToken
        farmPause, travelActive = true, true
        hoverTargetRoot, hoverTargetHum, pointReached = nil, nil, false
        task.spawn(guard(function()
            local t0 = os.clock()
            while my == flightToken and gui.Parent and os.clock() - t0 < 900 do
                local c = p.Character
                local r = c and c:FindFirstChild("HumanoidRootPart")
                if not r then break end
                hoverPoint = r.Position
                if pointReached then break end
                task.wait(0.1)
            end
            if my == flightToken then endFlight() end
        end))
    end)
    stopBtn.MouseButton1Click:Connect(function()
        flightToken = flightToken + 1
        endFlight()
    end)
end

----------------------------------------------------------------
-- ESP bằng khung giao diện (chạy mọi executor, không cần Drawing)
----------------------------------------------------------------
local setEsp
do
local espEntries, espList, espLast, espAccum, espConn = {}, {}, 0, 0, nil

local function newEsp()
    local e = {}
    e.box = make("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Parent = espLayer })
    e.boxStroke = make("UIStroke", { Thickness = 1.5, Color = state.ESPColor, Parent = e.box })
    e.name = make("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(160, 16), AnchorPoint = Vector2.new(0.5, 1),
        Font = Enum.Font.GothamBold, TextSize = 13, TextStrokeTransparency = 0.4, Text = "", Visible = false, Parent = espLayer })
    e.info = make("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(160, 14), AnchorPoint = Vector2.new(0.5, 0),
        Font = Enum.Font.GothamMedium, TextSize = 12, TextStrokeTransparency = 0.4, TextColor3 = C.White, Text = "",
        Visible = false, Parent = espLayer })
    e.hpBg = make("Frame", { BackgroundColor3 = C.Black, BorderSizePixel = 0, Visible = false, Parent = espLayer })
    e.hpFill = make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1), Parent = e.hpBg })
    e.line = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false, Parent = espLayer })
    return e
end
local function hideEsp(e)
    e.box.Visible, e.name.Visible, e.info.Visible, e.hpBg.Visible, e.line.Visible = false, false, false, false, false
end
local function removeEsp(e)
    for _, k in ipairs({ "box", "name", "info", "hpBg", "line" }) do e[k]:Destroy() end
    if e.hl then e.hl:Destroy() end
end

local function espCollect(cam)
    local arr = {}
    local cpos = cam.CFrame.Position
    local function add(model, label)
        local r = model:FindFirstChild("HumanoidRootPart")
        if r then arr[#arr + 1] = { model = model, label = label, d = (r.Position - cpos).Magnitude } end
    end
    if state.ESPPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            local c = p.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if p ~= player and h and h.Health > 0 then add(c, p.DisplayName) end
        end
    end
    if state.ESPMobs then
        for _, o in ipairs(getSearchRoot():GetChildren()) do
            if isAliveMonster(o) then add(o, o.Name) end
        end
    end
    table.sort(arr, function(a, b) return a.d < b.d end)
    local out = {}
    for i = 1, math.min(#arr, CONFIG.EspMax) do out[i] = arr[i] end
    return out
end

local function espStep(dt)
    espAccum = espAccum + dt
    if espAccum < 0.033 then return end
    espAccum = 0
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if os.clock() - espLast > 0.3 then espLast = os.clock() espList = espCollect(cam) end
    local vp = cam.ViewportSize
    local seen = {}
    for _, item in ipairs(espList) do
        local model = item.model
        local root = model.Parent and model:FindFirstChild("HumanoidRootPart")
        if root then
            seen[model] = true
            local e = espEntries[model]
            if not e then e = newEsp() espEntries[model] = e end
            local sp = cam:WorldToViewportPoint(root.Position)
            if sp.Z <= 0 then
                hideEsp(e)
            else
                local top = cam:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
                local bot = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3.2, 0))
                local y0 = math.min(top.Y, bot.Y)
                local h = math.max(math.abs(bot.Y - top.Y), 8)
                local w = h * 0.55
                local x0 = sp.X - w / 2
                local col = state.ESPColor

                e.box.Visible = state.ESPBox
                e.box.Position = UDim2.fromOffset(x0, y0)
                e.box.Size = UDim2.fromOffset(w, h)
                e.boxStroke.Color = col

                e.name.Visible = state.ESPName
                e.name.TextColor3 = col
                e.name.Text = item.label
                e.name.Position = UDim2.fromOffset(sp.X, y0 - 2)

                e.info.Visible = state.ESPDist
                e.info.Text = string.format("[%dm]", math.floor(item.d))
                e.info.Position = UDim2.fromOffset(sp.X, y0 + h + 2)

                local hum = model:FindFirstChildOfClass("Humanoid")
                local ratio = hum and math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1) or 1
                e.hpBg.Visible = state.ESPHp
                e.hpBg.Position = UDim2.fromOffset(x0 - 6, y0)
                e.hpBg.Size = UDim2.fromOffset(3, h)
                e.hpFill.Size = UDim2.new(1, 0, ratio, 0)
                e.hpFill.BackgroundColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 60)

                if state.ESPTracer then
                    local ox, oy = vp.X / 2, (state.ESPOrigin == "bottom" and vp.Y) or (state.ESPOrigin == "center" and vp.Y / 2) or 0
                    local dx, dy = sp.X - ox, sp.Y - oy
                    local len = math.sqrt(dx * dx + dy * dy)
                    e.line.Visible = true
                    e.line.BackgroundColor3 = state.TracerColor
                    e.line.Size = UDim2.fromOffset(len, 2)
                    e.line.Position = UDim2.fromOffset(ox + dx / 2, oy + dy / 2)
                    e.line.Rotation = math.deg(math.atan2(dy, dx))
                else
                    e.line.Visible = false
                end

                if state.ESPChams then
                    if not e.hl then e.hl = make("Highlight", { FillTransparency = 0.6, OutlineTransparency = 0, Parent = gui }) end
                    e.hl.Adornee = model
                    e.hl.FillColor, e.hl.OutlineColor = col, col
                    e.hl.Enabled = true
                elseif e.hl then
                    e.hl.Enabled = false
                end
            end
        end
    end
    for model, e in pairs(espEntries) do
        if not seen[model] then
            removeEsp(e)
            espEntries[model] = nil
        end
    end
end

function setEsp(on)
    if on and not espConn then
        espAccum, espLast = 1, 0
        espConn = RunService.RenderStepped:Connect(guard(espStep))
    elseif not on and espConn then
        espConn:Disconnect()
        espConn = nil
        for m, e in pairs(espEntries) do removeEsp(e) espEntries[m] = nil end
    end
end

local pEsp = addTab("esp", "tab_esp")
section(pEsp, "sec_show")
toggle(pEsp, "esp_on", "ESP", setEsp)
toggle(pEsp, "esp_players", "ESPPlayers")
toggle(pEsp, "esp_mobs", "ESPMobs")
toggle(pEsp, "esp_box", "ESPBox")
toggle(pEsp, "esp_name", "ESPName")
toggle(pEsp, "esp_dist", "ESPDist")
toggle(pEsp, "esp_hp", "ESPHp")
toggle(pEsp, "esp_tracer", "ESPTracer")
toggle(pEsp, "esp_chams", "ESPChams")
cycle(pEsp, "esp_origin", "ESPOrigin", {
    { v = "bottom", k = "o_bottom" }, { v = "center", k = "o_center" }, { v = "top", k = "o_top" } })
section(pEsp, "sec_color")
colorPicker(pEsp, "esp_color", "ESPColor")
colorPicker(pEsp, "esp_tcolor", "TracerColor")
end

----------------------------------------------------------------
-- AIM + FOV (chỉ chạy khi bật)
----------------------------------------------------------------
local setAim
do
local function aimPartOf(model)
    if state.AimPart == "Head" then
        return model:FindFirstChild("Head")
    elseif state.AimPart == "Feet" then
        return model:FindFirstChild("LeftFoot") or model:FindFirstChild("Left Leg") or model:FindFirstChild("HumanoidRootPart")
    end
    return model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
end

local function aimStep()
    fovCircle.Visible = state.ShowFov
    fovCircle.Size = UDim2.fromOffset(state.Fov * 2, state.Fov * 2)
    fovStroke.Color = state.FovColor
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local center = cam.ViewportSize / 2
    local bestPart, bestD = nil, state.Fov
    local function consider(model)
        local part = aimPartOf(model)
        if part then
            local sp = cam:WorldToViewportPoint(part.Position)
            if sp.Z > 0 then
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if d <= bestD then bestPart, bestD = part, d end
            end
        end
    end
    if state.AimTarget == "Players" then
        for _, p in ipairs(Players:GetPlayers()) do
            local c = p.Character
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if p ~= player and h and h.Health > 0 then consider(c) end
        end
    else
        for _, o in ipairs(getSearchRoot():GetChildren()) do
            if isAliveMonster(o) then consider(o) end
        end
    end
    if bestPart then
        cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, bestPart.Position), state.Smooth)
    end
end

local aimBound = false
function setAim(on)
    if on and not aimBound then
        aimBound = true
        RunService:BindToRenderStep("GumballAim", Enum.RenderPriority.Camera.Value + 1, guard(aimStep))
    elseif not on and aimBound then
        aimBound = false
        pcall(function() RunService:UnbindFromRenderStep("GumballAim") end)
        fovCircle.Visible = false
    end
end

local pAim = addTab("aim", "tab_aim")
toggle(pAim, "aim_on", "Aim", setAim)
cycle(pAim, "aim_part", "AimPart", {
    { v = "Head", k = "p_head" }, { v = "Body", k = "p_body" }, { v = "Feet", k = "p_feet" } })
cycle(pAim, "aim_target", "AimTarget", { { v = "Players", k = "t_players" }, { v = "Mobs", k = "t_mobs" } })
section(pAim, "sec_fov")
toggle(pAim, "aim_showfov", "ShowFov")
slider(pAim, "aim_fov", "Fov", 10, 360, 0)
slider(pAim, "aim_smooth", "Smooth", 0.05, 1, 2)
colorPicker(pAim, "aim_fovcolor", "FovColor")
end

----------------------------------------------------------------
-- CÀI ĐẶT
----------------------------------------------------------------
local unloaded = false
local unload

local pSet = addTab("set", "tab_set")
do -- chọn ngôn ngữ (lưới nút)
    local rows = math.ceil(#LANGS / 2)
    local f = row(pSet, 40 + rows * 36)
    L(f, "lang", 14, 6, -20, 24)
    local grid = make("Frame", { Size = UDim2.new(1, -20, 0, rows * 36), Position = UDim2.fromOffset(10, 34),
        BackgroundTransparency = 1, Parent = f })
    make("UIGridLayout", { CellSize = UDim2.new(0.5, -4, 0, 30), CellPadding = UDim2.fromOffset(8, 6),
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
    local buttons = {}
    local function paintLang()
        for code, b in pairs(buttons) do b.BackgroundColor3 = (code == lang) and C.Red or C.Off end
    end
    for i, lg in ipairs(LANGS) do
        local b = make("TextButton", { LayoutOrder = i, BackgroundColor3 = C.Off, Text = lg.name, Font = Enum.Font.GothamBold,
            TextSize = 12, TextColor3 = C.White, AutoButtonColor = false, Parent = grid })
        corner(b, 8)
        buttons[lg.v] = b
        b.MouseButton1Click:Connect(function()
            lang = lg.v
            paintLang()
            for _, fn in ipairs(relabel) do pcall(fn) end
        end)
    end
    paintLang()
end
do -- AntiBan (luôn bật)
    local f = row(pSet, 62)
    L(f, "antiban", 14, 6, -90, 22, 13)
    local d = L(f, "antiban_desc", 14, 30, -20, 28, 11)
    d.TextColor3 = C.Gray
    d.TextWrapped = true
    local pill = make("TextLabel", { Size = UDim2.fromOffset(44, 20), Position = UDim2.new(1, -56, 0, 7), BackgroundColor3 = C.Green,
        Text = "ON", Font = Enum.Font.GothamBlack, TextSize = 12, TextColor3 = C.Black, Parent = f })
    corner(pill, 10)
end
section(pSet, "sec_extra")
do
    local lighting = game:GetService("Lighting")
    local saved, disabled = nil, {}
    local function fpsBoost(on)
        if on then
            saved = saved or { shadows = lighting.GlobalShadows }
            lighting.GlobalShadows = false
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
            disabled = {}
            for _, d in ipairs(Workspace:GetDescendants()) do
                if (d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam")) and d.Enabled then
                    d.Enabled = false
                    disabled[#disabled + 1] = d
                end
            end
        else
            if saved then lighting.GlobalShadows = saved.shadows end
            for _, d in ipairs(disabled) do pcall(function() d.Enabled = true end) end
            disabled = {}
        end
    end
    toggle(pSet, "fpsboost", "FpsBoost", fpsBoost)
    toggle(pSet, "autobuso", "AutoBuso")
    task.spawn(function()
        while gui.Parent do
            if state.AutoBuso then
                local c = player.Character
                if c and c:FindFirstChild("HumanoidRootPart") and not c:FindFirstChild("HasBuso") then invoke("Buso") end
            end
            task.wait(2)
        end
    end)
end

----------------------------------------------------------------
-- NÚT TRÒN "G", THU NHỎ, ĐÓNG
----------------------------------------------------------------
local bubble = make("TextButton", { Name = "Bubble", Size = UDim2.fromOffset(58, 58), Position = UDim2.new(0, 40, 0.5, -29),
    BackgroundColor3 = C.White, Text = "G", Font = Enum.Font.GothamBlack, TextSize = 28, TextColor3 = C.White,
    AutoButtonColor = false, Visible = false, ZIndex = 20, Parent = gui })
corner(bubble, 29) stroke(bubble, C.White, 2, 0.4)
gradient(bubble, C.RedHi, C.RedDark, 90)

local function showMenu()
    bubble.Visible = false
    main.Visible = true
end
local function showBubble()
    local p = main.AbsolutePosition
    main.Visible = false
    if not bubble:GetAttribute("placed") then bubble.Position = UDim2.fromOffset(p.X + 10, p.Y + 10) end
    bubble.Visible = true
end
closeBtn.MouseButton1Click:Connect(showBubble)
makeDraggable(bubble, bubble, showMenu)
makeDraggable(titleBar, main, nil)

do
    local minimized = false
    miniBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        body.Visible = not minimized
        main.Size = minimized and UDim2.fromOffset(MW, 52) or UDim2.fromOffset(MW, MH)
    end)
end

selectTab("fam")

bind(UIS.InputBegan:Connect(function(i)
    if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
    local function inside(f)
        if not f.Visible then return false end
        local ap, as = f.AbsolutePosition, f.AbsoluteSize
        return i.Position.X >= ap.X and i.Position.X <= ap.X + as.X and i.Position.Y >= ap.Y and i.Position.Y <= ap.Y + as.Y + 50
    end
    if inside(main) or inside(bubble) then lastMenuInput = os.clock() end
end))

----------------------------------------------------------------
-- HỦY SCRIPT + ĐẾM NGƯỢC KEY
----------------------------------------------------------------
unload = function()
    if unloaded then return end
    unloaded = true
    state.AutoFarm, state.AutoSaber, state.AutoStat = false, false, false
    travelActive, farmPause = false, false
    state.Fly, state.Run, state.ESP, state.Aim = false, false, false, false
    stopFarm()
    autoStatToken = autoStatToken + 1
    setEsp(false)
    setAim(false)
    cleanupMove()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    gui:Destroy()
    genv.GumballUnload = nil
end
genv.GumballUnload = unload
gui.Destroying:Connect(function() if not unloaded then unload() end end)

local function fmtTime(sec)
    local d = math.floor(sec / 86400)
    local h = math.floor((sec % 86400) / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = math.floor(sec % 60)
    local clock = string.format("%02d:%02d:%02d", h, m, s)
    if d > 0 then return string.format("%d %s %s", d, tr("time_day"), clock) end
    return clock
end

task.spawn(function()
    local lastRecheck, lastFlush, lastSeq = os.clock(), 0, -1
    while not unloaded do
        local left = expiresAt - (os.time() + timeOffset)
        if left <= 0 then
            timerLabel.TextColor3 = C.RedHi
            timerLabel.Text = tr("expired_msg")
            task.wait(1.5)
            unload()
            return
        end
        timerLabel.TextColor3 = (left < 300) and C.RedHi or C.Green
        timerLabel.Text = tr("time_left") .. ": " .. fmtTime(left) .. "  (" .. tr("d_" .. keyType) .. ")"
        if (dbgLog.seq or 0) ~= lastSeq and os.clock() - lastFlush > 5 then
            lastFlush, lastSeq = os.clock(), dbgLog.seq or 0
            writeFile("gumball_log.txt", ((lastError ~= "") and (lastError .. "\n") or "") .. table.concat(dbgLog, "\n"))
        end
        -- Hỏi lại máy chủ mỗi 10 phút: key bị thu hồi / đổi máy thì dừng
        if CONFIG.ServerUrl ~= "" and os.clock() - lastRecheck > 600 then
            lastRecheck = os.clock()
            local okk, err = verifyOnline(readFile(CONFIG.KeyFile) or "")
            if not okk and err ~= "net" then unload() return end
        end
        task.wait(1)
    end
end)

if game.PlaceId ~= CONFIG.Sea1PlaceId then setStatus("st_sea", false) end
