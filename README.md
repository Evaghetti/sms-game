[![Master System](https://www.copetti.org/images/consoles/mastersystem/international.8865c9c84467b8c90fdc51dc4c7f77c6e8e3b940102462ad5d8377d56675ee19.png "Master System")](https://www.copetti.org/images/consoles/mastersystem/international.8865c9c84467b8c90fdc51dc4c7f77c6e8e3b940102462ad5d8377d56675ee19.png "Master System")
# SMS Game (Nome Provisório)
[![Quantidade de estelas no projeto](https://img.shields.io/github/stars/Evaghetti/sms-game "Quantidade de estelas no projeto")](https://img.shields.io/github/stars/Evaghetti/sms-game "Quantidade de estelas no projeto")  [![Bugs](https://img.shields.io/github/issues/Evaghetti/sms-game "Bugs")](https://img.shields.io/github/issues/Evaghetti/sms-game "Bugs") [![Meu twitter](https://img.shields.io/twitter/url?url=https%3A%2F%2Ftwitter.com%2FEvaghettiXD "Meu twitter")](http://https://img.shields.io/twitter/url?url=https%3A%2F%2Ftwitter.com%2FEvaghettiXD "Meu twitter")

Joguinho que eu to fazendo pra estudar desenvolvimento pro Sega Master System, nome do projeto provisório.
## Objetivo do jogo
Por enquanto não cheguei a planejar o que desejo que o jogo seja, to utilizando esse reposítorio para estudar como SMS funciona e, quando eu já estiver confortável com ele e o z80, começar a fazer um jogo de fato.
Quando chegar lá irei atualizar essa seção
## Contribuindo
Como eu to usando esse repositório pra fins educativos, caso tenham contribuições  eu gostaria que estejas sejam com formas de tornar o código mais eficiente. Não vou aceitar PR com features novas se não for direcionado a esse fim.
## Configurando ambiente
Para rodar a ROM gerada foi utilizado o emulador Meka
O projeto foi desenvolvido utilizando a binutils z80-elf da GNU, que infelizmente não está disponível na maioria dos package managers que eu procurei, mas acredito que boa parte do fonte seja compativel com outros assemblers, talvez não seja possível fazer proveito do Makefile apenas.
## Compilando a binutils
Caso queira utilizar o mesmo ambiente que eu utilizei, segue um passo a passo para compilar o ambiente por si.
Primeiramente clone o seguinte respositório
```bash
git clone git://sourceware.org/git/binutils-gdb.git
```
Quando o terminar de clonar o repositório, crie uma pasta build-z80 e entre dentro dela
```bash
mkdir build-z80
cd build-z80
```
Com a pasta criada, configure o ambiente para compilação.
```bash
../binutils-gdb/configure --prefix=PASTA_INSTALADORA --target=z80-elf
```
Troque `PASTA_INSTALADORA` pela pasta em que você deseja instalar a toolchain, agora é só buildar e se tudo der certo, instalar
```bash
make all
make install
```
## Compilando a ROM
Com o ambiente configurado basta rodar o Make file
```bash
make
```
Alguns arquivos serão gerados (na maioria object files), os mais importantes são o arquivo .sms (a ROM do jogo) e o arquivo .sym dessa ROM, que terá os símbolos para debug (O nome do arquivo precisa bater com o da ROM para que o Meka consiga carregar os símbolos
