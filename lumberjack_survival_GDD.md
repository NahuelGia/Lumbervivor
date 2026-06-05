# Lumbervivor
### Game Design Document — MVP
**Motor:** Godot 4.6 | **Género:** 2D Pixel Art Top-Down Survival Roguelike
**Versión:** 1.1

---

## 1. Resumen Ejecutivo

Lumbervivor es un juego de supervivencia roguelike en 2D con vista top-down y estética pixel art. El jugador encarna a un leñador que debe proteger su cabaña familiar de oleadas de zombies noche tras noche. Durante el día tala árboles para conseguir madera y fabrica mejoras en el banco de trabajo; al caer la noche los zombies atacan la cabaña y el jugador debe eliminarlos a todos para sobrevivir y avanzar a la siguiente ronda.

---

## 2. Concepto del Juego

### 2.1 Pilares de Diseño

- **Defensa de base:** la cabaña es el objetivo central a proteger, no el jugador.
- **Bucle roguelike:** al morir se reinicia desde cero, sin progresión persistente.
- **Gestión de recursos:** la madera es la única moneda del MVP; obliga a priorizar mejoras.
- **Escalado de dificultad:** cada noche los zombies son más fuertes y numerosos.

---

## 3. Bucle de Juego

### 3.1 Ciclo Día / Noche

Cada ronda se divide en dos fases claramente diferenciadas:

| Fase | Duración | Descripción |
|---|---|---|
| Día | 5 minutos | Sin zombies. El jugador puede talar árboles, recolectar madera y fabricar mejoras en el banco. |
| Noche | 5 min + barrido final | Aparecen zombies de forma continua. Al terminar los 5 min, la ronda no avanza hasta que no quede ningún zombie vivo. |

### 3.2 Transición entre Fases

- **Día → Noche:** la pantalla se oscurece gradualmente (Tween sobre `CanvasModulate`); los zombies comienzan a aparecer desde los bordes del mapa.
- **Noche → Día (victoria de ronda):** pantalla en negro, mensaje *"Sobreviviste la noche X"*, el jugador reaparece con vida máxima.
- **Muerte del jugador o destrucción total de la reja:** Game Over, vuelta al inicio (roguelike).

### 3.3 Condición de Fin de Noche

Al terminar los 5 minutos de noche, se bloquea la transición al día hasta que `active_zombies == 0`. El contador `active_zombies` en `main.gd` se incrementa al spawnearse cada zombie y se decrementa al recibir la señal `died`.

### 3.4 Escalado por Ronda

Cada noche el spawn aplica los siguientes multiplicadores sobre los stats base:

- **Cantidad de zombies:** `10 + (round - 1) * 2` — ronda 1: 10, ronda 2: 12, ronda 3: 14… (§10.1)
- **Vida:** `base_hp * (1.0 + 0.1 * (round - 1))`
- **Daño:** `base_damage * (1.0 + 0.1 * (round - 1))`

---

## 4. Jugador

### 4.1 Stats Base

| Stat | Valor |
|---|---|
| Vida máxima | 100 HP |
| Daño del hacha | 25 |
| Velocidad de movimiento | 250 px/s |

### 4.2 Comportamiento / IA

- Al aparecer, cada zombie elige su objetivo inicial de forma aleatoria ponderada:
  - **70%** de probabilidad → foco en la reja / barricada de la cabaña.
  - **30%** de probabilidad → foco en el jugador.
- Una vez que el zombie comienza a golpear la reja o la barricada, ignora al jugador completamente y solo ataca la estructura hasta destruirla o morir.
- Los zombies con foco en el jugador lo persiguen activamente.

---

## 5. Cabaña y Estructuras Defensivas

### 5.1 Cabaña

La cabaña es el hogar de la familia del leñador y el objeto central a defender. No es destruible directamente; su protección depende de la reja y las barricadas.

### 5.2 Reja

| Campo | Valor |
|---|---|
| HP base | 200 HP |
| Reparable | Sí (barricada de madera añade +100 HP) |
| Destrucción | Si la reja llega a 0 HP → Game Over |
| Clase GDScript | `CabinFence` (StaticBody2D) — pendiente de implementar |

### 5.3 Barricada de Madera

| Campo | Valor |
|---|---|
| Tipo | Mejora crafteable (un solo nivel — no apilable) |
| Coste | 6 madera |
| Efecto | +100 HP a la reja de la cabaña |
| Disponibilidad | Solo fabricable de día |
| Clase GDScript | `WoodBarricade` (StaticBody2D) — pendiente de implementar |

---

## 6. Recursos y Banco de Mejoras

### 6.1 Recursos (MVP)

| Campo | Valor |
|---|---|
| Recurso | Madera |
| Obtención | Talar árboles del bosque (+6 madera por árbol) |
| Árboles en mapa | 15 por día → máximo ~90 madera por fase de día |
| Uso | Pagar mejoras en el banco de trabajo |
| Persistencia | Se pierde al morir (roguelike) |

### 6.2 Banco de Mejoras

Accesible durante el día únicamente (tecla B). Mejoras de un único nivel — no apilables.

| Mejora | Coste | Efecto |
|---|---|---|
| Hacha mejorada | 8 madera | `axe.damage += 15` (25 → 40) |
| Armadura de madera | 10 madera | `player.max_health += 30` (100 → 130) |
| Barricada de madera | 6 madera | `fence.current_health += 100` (hasta un máximo de `base_hp`) |

> **Nota de implementación:** `CraftingBench` escribe directamente en `axe.damage` y `player.max_health`. No existe `player.axe_damage` — fue eliminado. Ver §10.3.

---

## 7. Zombies

### 7.1 Tipos de Zombie

| Tipo | HP base | Daño base | Velocidad | Color placeholder | Disponible desde |
|---|---|---|---|---|---|
| Normal | 50 HP | 10 | 75 px/s | Rojo (#CC3333) | Ronda 1 |
| Corredor | 35 HP | 8 | 130 px/s | Amarillo (#DDCC00) | Ronda 3 |
| Tanque | 120 HP | 20 | 45 px/s | Bordó (#8B0000) | Ronda 3 |

Los stats anteriores son los **valores base**. El escalado por ronda (§3.4) multiplica HP y daño sobre estos valores.

### 7.2 Rondas 1–2

- Solo zombies normales.
- El escalado de stats empieza a aplicarse desde ronda 2 (ronda 1 usa stats base).

### 7.3 Ronda 3 en adelante

- Se desbloquean el corredor y el tanque.
- Proporción de spawn: 50% normal, 30% corredor, 20% tanque.
- Cada ronda aplica +10% a HP y daño de todos los tipos.

### 7.4 Game Over y Reinicio

- **Condiciones de Game Over:** el jugador muere (`player.died`), o la reja es destruida (`fence.destroyed`).
- Al hacer Game Over se regresa al estado inicial (ronda 1, sin mejoras, sin recursos).
- No hay progresión persistente entre runs (roguelike puro en MVP).

---

## 8. Arquitectura Técnica (Godot 4.6)

### 8.1 Árbol de Escenas (Runtime)

```
Main (Node2D)                    ← main.gd: spawning, estado, ciclo día/noche, toggle banco
├── World (Node2D)
│   ├── Terrain (Polygon2D)      ← placeholder visual
│   ├── Cabin (Node2D)           ← cabaña + reja
│   ├── Trees (Node2D)           ← contenedor de ChoppableTree
│   ├── Zombies (Node2D)         ← contenedor de Zombie
│   └── Player (CharacterBody2D) ← player.gd
│       ├── Axe (Area2D)         ← axe.gd: swing hitbox
│       └── Camera2D
├── DayNightTimer (Timer)        ← 300s (5 min), autostart=true
├── ZombieSpawnTimer (Timer)     ← activo solo durante la noche
└── UI (CanvasLayer)
    ├── HUD (Control)            ← vida, madera, ronda, fase
    └── CraftingBench (Control)  ← visible de día, tecla B
```

### 8.2 Clases Principales

| class_name | Archivo | Base | Estado |
|---|---|---|---|
| `Player` | `scenes/characters/player/player.gd` | CharacterBody2D | ✅ |
| `Axe` | `scenes/components/axe/axe.gd` | Area2D | ✅ |
| `Zombie` | `scenes/characters/zombie/zombie.gd` | CharacterBody2D | ⬜ IA pendiente |
| `ChoppableTree` | `scenes/objects/tree/tree.gd` | StaticBody2D | ✅ |
| `CabinFence` | `scenes/objects/cabin/fence.gd` | StaticBody2D | ⬜ PENDIENTE |
| `WoodBarricade` | `scenes/objects/cabin/barricade.gd` | StaticBody2D | ⬜ PENDIENTE |
| `HUD` | `scenes/ui/hud/hud.gd` | Control | ⬜ stubs |
| `CraftingBench` | `scenes/ui/crafting/crafting.gd` | Control | ⬜ PENDIENTE |

### 8.3 Input Actions

| Acción | Binding | Estado |
|---|---|---|
| `move_left` | A / ← | ✅ Implementado |
| `move_right` | D / → | ✅ Implementado |
| `move_up` | W / ↑ | ✅ Implementado |
| `move_down` | S / ↓ | ✅ Implementado |
| `attack` | Click izquierdo | ✅ Implementado |
| `push` | Click derecho | ⬜ Pendiente |
| `open_bench` | B | ⬜ Pendiente |

### 8.4 Capas de Colisión

Configurar antes de implementar la IA de zombies:

| Capa | Uso |
|---|---|
| Capa 1 | Jugador |
| Capa 2 | Zombies |
| Capa 3 | Árboles |
| Capa 4 | Reja / Barricada |

---

## 9. Estado de Implementación (MVP)

| Sistema | Estado | Notas |
|---|---|---|
| Movimiento del jugador (WASD + mouse facing) | ✅ Listo | |
| Swing de hacha + hitbox | ✅ Listo | Cooldown, arco, un hit por swing |
| `take_damage` en árbol | ✅ Listo | Señal `chopped`, `queue_free` |
| `take_damage` en zombie | ✅ Listo | Señal `died`, `queue_free` |
| Recolección de madera | ✅ Listo | +6 por árbol, señal `wood_changed` |
| Spawning inicial | ✅ Listo | 15 árboles + 5 zombies |
| Capas de colisión | ⬜ Pendiente | Bloque A |
| IA / movimiento de zombies | ⬜ Pendiente | Bloque B — `_physics_process` vacío |
| Daño al jugador | ⬜ Pendiente | Bloque B |
| Cabaña y reja | ⬜ Pendiente | Bloque C |
| HUD (vida, madera, ronda, fase) | ⬜ Pendiente | Bloque E |
| Ciclo día / noche (5 min c/u) | ⬜ Pendiente | Bloque D |
| Banco de mejoras / CraftingBench | ⬜ Pendiente | Bloque E — reemplaza Shop P-key |
| Click derecho (empuje) | ⬜ Pendiente | Bloque B o E |
| Tipos de zombie (corredor / tanque) | ⬜ Pendiente | Bloque F — Ronda 3+ |
| Escalado de dificultad por ronda | ⬜ Pendiente | Bloque F |
| Pantalla de Game Over / Victoria | ⬜ Pendiente | Bloque G |
| Pixel art / sprites finales | ⬜ Pendiente | Post-MVP |

---

## 10. TODOs y Decisiones Pendientes

### ~~10.1 Algoritmo de Spawn Nocturno~~ ✅ RESUELTO

| Decisión | Valor confirmado |
|---|---|
| Estilo de spawn | Continuo con intervalo decreciente (no oleadas fijas) |
| Posiciones de spawn | Bordes del mapa (punto aleatorio sobre cualquiera de los 4 bordes) |
| Zombies en ronda 1 | 10 (`base_count = 10`) |
| Fórmula de cantidad | `10 + (round - 1) * 2` → 10, 12, 14… |
| Intervalo del timer | 8 s en ronda 1; `max(2.0, 8.0 - (round - 1) * 0.5)` s por ronda |
| Máximo concurrente | 15 zombies en pantalla simultáneamente |

### ~~10.2 Balanceo de Economía~~ ✅ RESUELTO

Costes confirmados: hacha=8, armadura=10, barricada=6. Mejoras de un único nivel. Ver §6.2.

### ~~10.3 Sincronización `axe_damage` / `axe.damage`~~ ✅ RESUELTO

Decisión: eliminar `Player.axe_damage`. Fuente de verdad: `Axe.damage`. `CraftingBench` escribe directo en `axe.damage`.

### 10.4 Condición de Fin de Noche ✅ DISEÑADO

Contador `active_zombies` en `main.gd`. Ver §3.3. Pendiente de implementar (Bloque E).

### ~~10.5 Configuración de Capas de Colisión~~ → Bloque A

Decisión tomada. Ver §8.4. Pendiente de aplicar en `project.godot` y `.tscn`.

---

## 11. Plan de Implementación por Bloques

Orden de ejecución: **A → B → C → D → E → F → G → H**

### Bloque A — Setup & Fixes
**Prerrequisito:** ninguno

1. Configurar 4 capas de colisión en `project.godot` y todos los `.tscn` existentes (§8.4)
2. Corregir `Player.move_speed`: 150 → 250 px/s (§4.1)
3. Eliminar `Player.axe_damage` — fuente de verdad: `Axe.damage` (§10.3)

### Bloque B — Zombie AI & Targeting
**Prerrequisito:** Bloque A

1. Implementar `_physics_process` en `zombie.gd`: mover hacia `target` a `move_speed`
2. Agregar variable `target: Node2D` en `zombie.gd`, asignada al spawnear desde `main.gd`
3. Asignación 70/30 en `main.gd`: 70% → `CabinFence`, 30% → `Player`
4. Contador `active_zombies` en `main.gd`: incrementar al spawn, decrementar en señal `died`

### Bloque C — Cabin & CabinFence
**Prerrequisito:** Bloque A

1. Crear placeholder visual de cabaña (`ColorRect` o `Polygon2D`)
2. Crear `fence.gd`: `StaticBody2D`, 200 HP, `take_damage()`, señal `destroyed`
3. Crear `fence.tscn` y agregarlo como hijo de `Cabin` en `world.tscn`
4. Conectar `fence.destroyed` → Game Over provisional en `main.gd`

### Bloque D — Damage Exchange & Push
**Prerrequisito:** Bloques B + C

> ⚠️ **Antes de implementar este bloque**, definir en el GDD los siguientes valores que aún no están especificados:
> - **Rango de ataque del zombie** (px): distancia mínima para que el zombie comience a atacar.
> - **Intervalo de ataque del zombie** (seg): cada cuántos segundos el zombie inflige daño.
> - **Rango del push** (px): radio del `Area2D` del empuje del jugador.

1. Implementar `player.take_damage(amount)` + emisión de señal `died`
2. Agregar timer de ataque en `zombie.gd`: atacar target cuando está en rango
3. Zombie ataca jugador: `player.take_damage(attack_damage)`
4. Zombie ataca reja: `fence.take_damage(attack_damage)`
5. Mapear acción `push` (right click) en `project.godot`
6. Implementar push en `player.gd`: escanear `Area2D` y empujar zombies cercanos

### Bloque E — Day/Night Cycle
**Prerrequisito:** Bloque C + §10.1 resuelto ✅

1. Agregar `DayNightTimer` (300 s, `autostart=true`) a `main.tscn`
2. Variable `phase: String` (`"DAY"` / `"NIGHT"`) en `main.gd`
3. Transición Día→Noche: `Tween` sobre `CanvasModulate`, iniciar `ZombieSpawnTimer`
4. Spawn nocturno: posiciones desde bordes del mapa, intervalo `max(2.0, 8.0 - (round-1)*0.5)` s, máx. 15 simultáneos
5. Condición Noche→Día: `active_zombies == 0` → nueva fase día
6. Inicio de día: curar jugador al máximo, respawnear 15 árboles, incrementar `round`
7. Overlay de victoria: `"Sobreviviste la noche X"` antes de iniciar el día

### Bloque F — HUD & CraftingBench
**Prerrequisito:** Bloques D + E

1. Implementar `HUD.update_health()`, `HUD.update_wood()`, mostrar ronda y fase
2. Conectar `player.health_changed → hud.update_health`, `player.wood_changed → hud.update_wood`
3. Eliminar `shop.gd` y `shop.tscn`, limpiar referencias en `main.gd`
4. Crear `crafting.gd` + `crafting.tscn`: tecla B, visible solo de día
5. Tres mejoras: hacha (`axe.damage += 15`), armadura (`player.max_health += 30`), barricada (`fence.current_health += 100`)

### Bloque G — Zombie Types & Scaling
**Prerrequisito:** Bloque E

1. Agregar `enum ZombieType { NORMAL, RUNNER, TANK }` en `zombie.gd`
2. Stats por tipo según §7.1
3. Lógica de spawn mix en `main.gd`: rondas 1–2 = 100% normal; ronda 3+ = 50% / 30% / 20%
4. Aplicar fórmula de escalado al spawnear: `stat * (1.0 + 0.1 * (round - 1))` (§3.4)

### Bloque H — Game Over & Victory Screens
**Prerrequisito:** Bloques D + E + F

1. Crear escena `GameOverScreen`
2. Conectar `player.died → GameOverScreen` y `fence.destroyed → GameOverScreen`
3. Reset completo al hacer Game Over: `round = 1`, `wood = 0`, sin mejoras, respawnear todo
4. Verificar overlay de victoria de ronda (implementado en Bloque E)
