# Sorting illustration prompts

Built-in imagegen, transparent-background generation, 2026-10-23. Each request
used the following shared prompt followed by its row-by-row subject list.

> Use case: illustration-story. Asset type: production sprite atlas for a
> preschool sorting game in Flutter. Create ONE transparent sprite atlas,
> exactly 4 columns by 3 rows, 12 equally sized square cells. Canvas 1536 by 1152
> or any exact 4:3 ratio. Invisible grid only: no visible cell borders, no labels,
> no letters, no text, no numbers, no backdrop, no shadows outside each object.
> Each object centered in its cell with 12% clear padding, no object crossing
> cell edges. Consistent premium children's worksheet illustration style: warm
> friendly kawaii cartoon, clean dark brown outlines, softly shaded bright
> colors, gentle dimensional highlights, clear silhouettes, charming rounded
> proportions, polished storybook quality. True transparent alpha background.
> Each cell must contain exactly the specified object, every cell filled,
> precise row order.

## Teeth subjects

Row 1: friendly sad tooth with brown sugary spots, a small frown and tiny black
arms down; sparkling happy pale-blue healthy tooth with arms raised; smiling
whole-grain bread slice; smiling purple grapes. The sad tooth must not be
frightening.

Row 2: friendly broccoli; small plain-white yogurt cup with pink foil rim,
spoon and smiling face; smiling red tomato; red fizzy soda can without writing
and with a tiny concerned face.

Row 3: cupcake with cream frosting and red cherry; pink round lollipop on a
stick; pink layer-cake slice; orange cereal box with a small bowl pictured on
the front. These four have tiny concerned faces. No text.

## Weather subjects

Row 1: smiling grey raincloud with five blue raindrops; smiling golden sun with
short golden rays and two sparkles; open red umbrella with white raindrop motifs
and curved handle; pair of yellow rubber rain boots.

Row 2: front-facing blue hooded raincoat; purple waterproof rain hat with chin
cord; pair of green rubber rain boots; pink wide-brimmed sun hat with yellow
ribbon and bow.

Row 3: glossy black sunglasses; orange sunscreen tube with a white sun symbol
and no writing; open white folding hand fan with wooden ribs; glossy multicolor
beach ball. No faces except on the sun and cloud.

## Laundry subjects

Row 1: friendly white front-loading washer with blue basket overflowing with
colorful dirty clothing, brown mud on clothes and a smiling face on the washer;
friendly open warm wooden wardrobe with hanging colorful shirts, folded stacks
and a smiling face at the top; yellow short-sleeved T-shirt with obvious brown
mud splashes; green shorts with obvious brown mud splashes.

Row 2: blue shorts with mud splashes; pink short-sleeved T-shirt with mud
splashes; white short-sleeved T-shirt with mud splashes; clean blue shorts.

Row 3: clean white T-shirt; clean green shorts; clean yellow T-shirt; clean pink
T-shirt. All clothes face forward. Clean variants match the dirty garments'
silhouettes and colors. No faces on clothes.

## Processing

The actual generated sources are 1448×1086. The output is checked visually,
then silhouettes are extracted and optimized with `prepare_sorting_assets.cjs`.
The resulting project assets are `assets/gen/images/helpers/*.webp`. Source
atlases remain in Codex's generated-images directory and are not application
assets.
