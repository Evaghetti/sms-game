#!/usr/bin/env python3

from PIL import Image, ImageFile
from sys import stderr
import argparse

TILE_HEIGHT = 8  # Largura em pixels de cada tile
TILE_WIDTH  = 8  # Altura em pixels de cada tile
STEP_COLOR  = 85 # Master system usa um sistema de cores de 3 bits, pra converter para RGB, multiplicamos cada cor por 85
    
def proccessTile(image: ImageFile, paletteTile: list, xPos: int, yPos: int) -> list:
    """Processa um espaço de 8x8 em image apartir de xPos e yPos, salvando as cores utilizadas em paletteTile

    Args:
        image (ImageFile): Imagem cujo os dados do tile serão processados
        paletteTile (list): Paleta de cores resultante
        xPos (int): Posição x do primeiro pixel do tile sendo gerado em image
        yPos (int): Posição y do primeiro pixel do tile sendo gerado em image

    Returns:
        list: Os dados do tile gerado
    """
    tileData: list = []

    for y in range(yPos, yPos + TILE_HEIGHT):
        indicesRow: list = []
        # Verifica todos os pixels horizontais do tile atual
        for x in range(xPos, xPos + TILE_WIDTH):
            r, g, b, a = image.getpixel((x, y))

            # Se for um pixel transparente usa a primeira cor da paleta (vulgo, transparente)
            if a == 0:
                indicesRow.append(0)
                continue

            # Converte um valor RGB para os valores que o master system entende
            smsR: int = int(r / STEP_COLOR)
            smsG: int = int(g / STEP_COLOR)
            smsB: int = int(b / STEP_COLOR)
            colorInSMS = (smsB << 4) | (smsG << 2) | (smsR)

            # Caso essa cor já esteja disponível na paleta de cores atual, usa o indice dela.
            try:
                indexPalette = paletteTile.index(colorInSMS, 1)
            # Se não, adiciona ela na paleta e pega a ultima posição dela.
            except ValueError:
                paletteTile.append(colorInSMS)
                indexPalette = len(paletteTile) - 1
            
            # Acrescenta nos indices dessa linha o indice da paleta atual.
            indicesRow.append(indexPalette)
        
        for i in range(0, len(indicesRow), 8):
            # Pega 8 indices por vez
            currentSection = indicesRow[i : i + 8]

            # O master system usa 4 bytes para cada linha do tile, cada iteração desse looping
            # é um byte
            for _ in range(4):
                resultingByte = 0
                
                # Master system usa um sistem planar, ou seja, se o primeiro pixel usar a cor 3 e o restante for transparente
                # O binário do tile seria algo como:
                # 0b10000000
                # 0b10000000
                # 0b00000000
                # 0b00000000
                # Então para cada indice na paleta, um shift right é feito e o bit excluido
                # É colocado no bit atual do byte resultado
                for currentBit in range(len(currentSection)):
                    currentSection[currentBit], carry = currentSection[currentBit] >> 1, currentSection[currentBit] & 1
                    carry <<= (7 - currentBit)
                    resultingByte |= carry
                tileData.append(resultingByte)
    
    return tileData

def findNot(subject, search, start: int = 0) -> int:
    """Procura dentro de subject qualquer valor diferente de search apartir de start

    Args:
        subject (str|list): Container que será percorrido
        search (any): Qual valor não deve estar presente para retorno com sucesso
        start (int, optional): Primeira posição para começar a busca. Defaults to 0.

    Returns:
        int: Posição da primeira ocorrencia de um valor diferente de search, do contrário -1
    """
    for i in range(start, len(subject), 1):
        if subject[i] != search:
            return i
    return -1

if __name__ == "__main__":
    # Configura argumentos pra aplicação
    parser = argparse.ArgumentParser(description="Converts an image file to a assembly file compatible with the Sega Master System")
    parser.add_argument("--out", "-o", help="Which folder to save the result (default: current folder)", default=".", type=str)
    parser.add_argument("path", metavar="image", type=str, nargs=1, help="File that will be converted")
    args = parser.parse_args()

    # Abre a imagem e verifica se ela é válida pra essa aplicação
    try:
        pathToImage: str = args.path[0]
        imageBeingRead: ImageFile = Image.open(pathToImage)

        if imageBeingRead.width % 8 != 0 or imageBeingRead.height % 8 != 0:
            raise RuntimeError
    except FileNotFoundError:
        print(f"Imagem {pathToImage} inexistente", file = stderr)
        exit(1)
    except RuntimeError:
        print(f"Imagem {pathToImage} não possui dimensões corretas", file = stderr)
        exit(1)

    palette: list = [0] # Paleta de cores, primeira cor é preta (transparencia)
    tileData: list = [] # Tiles gerados

    # Incrementando de 8 em 8 tanto na horizontal quanto na vertical
    # Gera um tile por vez.
    for y in range(0, imageBeingRead.height, 8):
        for x in range(0, imageBeingRead.width, 8):
            tileData += proccessTile(imageBeingRead, palette, x, y)

    # Procura o primeiro tile que não for 0
    newIndex = findNot(tileData, 0)
    # Enquanto existir tiles que não forem 0, procura um tile que não seja 0
    while newIndex != -1:
        currentIndex = newIndex
        newIndex = findNot(tileData, 0, currentIndex + 1)

    # Assim que encontrar, arredonda pro próximo valor com 8 e deleta o restante.
    currentIndex += 8 - currentIndex % 8
    del tileData[currentIndex:]

    # Gera um arquivo .asm com os bytes da paleta e dos tiles
    with open(args.out + "/" + pathToImage[pathToImage.rfind("/") + 1 : pathToImage.find(".")] + ".asm", "w") as fileOutput:
        print(".data", file=fileOutput)
        print("PaletteData:", file = fileOutput)
        for i in range(0, len(palette), 16):
            print(".db", end=" ", file = fileOutput)
            currentLine = [f"${color:x}" for color in palette[i : i + min(16, len(palette) - i)]]
            print(*currentLine, sep = ",", file = fileOutput)
        print("PaletteDataEnd:\n", file = fileOutput)

        print("TileData:", file = fileOutput)
        for i in range(0, len(tileData), 16):
            print(".db", end=" ", file = fileOutput)
            currentLine = [f"${tile:x}" for tile in tileData[i : i + min(16, len(tileData) - i)]]
            print(*currentLine, sep = ",", file = fileOutput)
        print("TileDataEnd:", file = fileOutput)
