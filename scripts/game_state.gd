class_name GameState
extends RefCounted

## Guarda dados que precisam sobreviver à troca de cena.

## Preenchido pelo menu de jogadores ao clicar em "Começar".
## players[i] = {"skin": int, "is_ai": bool}  (use CatSkins.apply para a skin)
static var player_count := 4
static var players: Array[Dictionary] = []

## Usado só pela tela antiga de escolha de um único gato (character_select).
static var selected_skin := 0
