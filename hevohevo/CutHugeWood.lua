-- #################################################################
-- Huge wood cutter, version 0.3a
-- hevohevo, License: MIT
-- Twitter: @hevohevo, http://hevohevo.hatenablog.com/

-- 説明: 松の巨木(2x2)を2本使った木材伐採場プログラムです。

-- 使い方:
--  松の苗木をできるだけ多くインベントリに入れる（ただし丸太用に3スロット程度は空けておく）
--  以下の俯瞰図どおりに苗木とタートルを配置
--  採取した木材はスタート地点に戻ってから真下にドロップします

-- 苗: 松の苗木を植える、タ: タートル、上が北向き ***方角は絶対に守ること***
--   苗苗
--   苗苗
-- 苗苗タ
-- 苗苗

-- ###############################################################
-- Config
local allow_blocks = {"minecraft:log", "minecraft:leaves"} -- 丸太と葉は伐採してよい
local deny_blocks = {"dirt", "grass"} -- 土（草）ブロックは土台なので破壊不許可
local spruce_sapling = {"minecraft:sapling", 1} -- 松の苗木はダメージ値1
local min_fuel_level = 200
local sleep_time = 60 -- sec

-- ###############################################################
-- Funcitons

-- 隣接するブロックが、指定ブロック名とマッチしたらtrue
-- 第1引数：ブロック名文字列（部分一致）またはその配列、第2引数：調べる方向の関数
-- 例： findBlock({"dirt", "grass"}, turtle.inspectDown) => true (下に土があった）
function findBlock(names, inspect_func)
  local status, detail = inspect_func()
  if not status then return false end -- ブロックが存在しないときはfalse返す
  if type(names)=="string" then names = {names} end
  for i,name in ipairs(names) do
    if string.match(detail["name"],name) then
      return true -- ブロック名称（複数）のいずれかがマッチしたらtrue
    end
  end
  return false -- いずれもマッチせずfalse
end

-- 指定スロットにあるアイテムが、指定アイテム名(damage値はオプション)にマッチしたらtrue
-- ## _matchSlotWithName(slot_num, item_name, [item_damage]) => true/false
local function _matchSlotWithName(slot, name, damage)
  local detail = turtle.getItemDetail(slot) -- アイテムなし: nil、アイテムあり: table
  if detail and string.match(detail["name"],name) then  -- アイテムが存在し、かつアイテム名がマッチする
    if (damage == nil) or (damage == detail["damage"]) then  -- damage値の指定なし、あるいは指定がありそれが一致
      return true -- マッチする
    end
  end
  return false -- マッチしない
end

-- ## getAllItemCount(item_name_str, [damage_int]) => インベントリ内アイテム総数
function getAllItemCount(item_name, damage)
  local total = 0
  for i=1,16 do
    if _matchSlotWithName(i, item_name, damage) then
      total = total + turtle.getItemCount(i)
    end
  end
  return total
end

-- ## selectItem(item_name, [damage]) => アイテム名とマッチするアイテムスロットを選択
function selectItem(name, damage) 
  for i=1,16 do
    if _matchSlotWithName(i , name, damage) then
      turtle.select(i)
      return true -- アイテムを見つけスロット選択できたらtrue
    end
  end
  return false, "No item to match" -- アイテムが見つからないfalse
end

-- 伐採してもよいブロックだけ伐採： digFor() / digDownFor() / digUpFor()
function digFor(block_names) -- 正面用
  block_names = block_names or allow_blocks
  if findBlock(block_names, turtle.inspect) then
    turtle.dig()
  end
end
function digDownFor(block_names) -- 真下用
  block_names = block_names or allow_blocks
  if findBlock(block_names, turtle.inspectDown) then
    turtle.digDown()
  end
end
function digUpFor(block_names) -- 真上用
  block_names = block_names or allow_blocks
  if findBlock(block_names, turtle.inspectUp) then
    turtle.digUp()
  end
end

-- 上か正面に伐採できるブロックがある限り、ずっと上に伐採しつつ上昇
-- 苗木をできるだけ回収するため回転上昇しながら葉も伐採する。
function revolveUp()
  while turtle.detect() or turtle.detectUp() do
    for i=1,4 do
      digFor()
      turtle.turnRight()
    end
    digUpFor()
    turtle.up()
  end
end

-- 下に土（草）ブロックを発見するまで下に回転伐採しつつ降りる
function revolveDown()
  -- 真下が破壊不許可ブロック以外ならwhile回して下に降りる
  while not findBlock(deny_blocks, turtle.inspectDown) do
    digDownFor()
    turtle.down()
    for i=1,4 do
      digFor()
      turtle.turnRight()
    end
  end
end

-- 汚いplant()関数とcutHugeWood()関数を見やすくするための小さなサブ関数
local function _digAndFwd()
  digFor()
  turtle.forward()
end
local function _turn180()
  turtle.turnRight()
  turtle.turnRight()
end
local function _getSapling()  -- できるだけ苗木を回収したい
  turtle.select(1)
  turtle.suck();  turtle.suckUp()
end
local function _plant()
  digFor() -- 片方の巨木伐採中にもう片方が成長し、空間を葉で埋めてしまう恐れに備えて
  selectItem(unpack(spruce_sapling));  turtle.place() -- 苗木を選択して植える
  _getSapling()
end

-- 苗木を植える。
-- もう片方の巨木が生長して空間を葉で埋めてしまう恐れのため後進は不可。常に伐採＆前進
function plant()
  -- 現在位置は2x2巨木の南西/北西、向きは西/北
  turtle.turnRight()
  _digAndFwd()
  _turn180()
  _plant() -- 苗木植える（南西/北西）
  turtle.turnLeft()
  _digAndFwd()
  _turn180()
  _plant() -- 苗木植える（北西/北東）
  turtle.turnLeft()
  _plant() -- 苗木植える（南東/南西）
  turtle.turnLeft()
  _digAndFwd()
  _turn180()
  _plant() -- 苗木植える（北東/南東）
end


-- 伐採したり、伐採後の地面に苗木を植えたり
function cutHugeWood()
  _digAndFwd()
  
  -- 2x2大木の北東（南東）幹を回転上昇開始
  revolveUp()

  -- 南西（北西）幹の位置に移動
  turtle.turnLeft()
  _digAndFwd()
  turtle.turnRight()
  _digAndFwd()
  
  -- 2x2大木の南西（北西）幹を回転下降開始
  revolveDown()
  
  -- 伐採終了、苗木植える
  plant()
end

-- ###############################################################
-- main
while true do
  for i=1,4 do -- 四方を見るけれど結局は北と西側にしか巨木は無い
    turtle.select(1)
    
    -- 燃料が min_fuel_level 以下のときはエラー終了
    print("Fuel: ",turtle.getFuelLevel())
    assert(turtle.getFuelLevel()>min_fuel_level, "more fuel!")

    -- インベントリ内の松の苗木の総数が4つ未満ならばエラー終了
    assert(getAllItemCount(unpack(spruce_sapling))>=4, "Required 4 spruce-sapling")

    -- インベントリ内の丸太を全て下にドロップ
    while selectItem("minecraft:log") do turtle.dropDown() end 

    -- 巨木が生長することで正面が丸太（log）なら伐採開始
    if findBlock("minecraft:log", turtle.inspect) then
      cutHugeWood()
    end
    
    turtle.turnRight()
    _getSapling()
  end
  
  os.sleep(sleep_time)
end