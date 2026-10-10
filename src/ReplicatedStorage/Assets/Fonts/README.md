# Assets/Fonts — RobotoCondensed (SIL OFL)

## Fichiers attendus

| Fichier | Usage | Asset ID |
|---|---|---|
| RobotoCondensed-Regular.ttf | Texte courant (Body) | à remplacer |
| RobotoCondensed-Bold.ttf | Titres, prix, chiffres | à remplacer |
| RobotoCondensed-Light.ttf | Textes secondaires (optionnel) | à remplacer |

## Licence

Roboto Condensed — Google Fonts, **SIL Open Font License 1.1**
Autorisation commerciale incluse. Attribution requise dans les crédits du jeu.

## Upload Creator Hub

1. Aller sur **Creator Hub → Creations → Fonts**
2. Uploader `RobotoCondensed-Regular.ttf` et `RobotoCondensed-Bold.ttf`
3. Remplacer les placeholders `rbxassetid://0` dans `Theme.lua` par les IDs générés

## Fallback

Si les asset IDs sont à 0, `Theme.Text()` utilise `Builder Sans` (intégré Roblox).
