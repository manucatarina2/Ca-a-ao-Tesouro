# Caça ao Tesouro

Um aplicativo interativo de geolocalização desenvolvido em Flutter para a disciplina de PPDM (Programação para Dispositivos Móveis). O aplicativo transforma o mundo real em um tabuleiro de caça ao tesouro, guiando o usuário até coordenadas específicas utilizando GPS, dicas visuais dinâmicas, uma bússola e efeitos sonoros!

---

## Desenvolvido por:
- **Manuela Catarina**
- **Ana Victória**
- **Sophia Morgado**

---

##  Funcionalidades

- **Rastreamento em Tempo Real:** Utiliza o GPS do dispositivo para monitorar a localização atual do usuário.
- **Cálculo de Passos:** Calcula a distância até o tesouro e a converte em "passos" (considerando 0,8 metros por passo).
- **Feedback de Proximidade Dinâmico:**
  -  **Frio:** Longe do tesouro (≥ 50 passos).
  -  **Morno:** Se aproximando (< 50 passos).
  -  **Quente:** Perto (< 25 passos).
  -  **Muito Quente:** Quase lá (< 10 passos).
- **Bússola Interativa:** Uma seta giratória que aponta a direção correta do tesouro baseada na sua posição atual.
- **Efeitos Visuais Premium:** Interface moderna com paleta "Rosa Premium", estilo *Glassmorphism*, animações de pulso, partículas e efeito *shimmer*.
- **Recompensa Sonora:** Reproduz uma música/efeito sonoro de comemoração automaticamente assim que o usuário encontra o tesouro (menos de 10 passos).

---

## 🛠️ Tecnologias Utilizadas

- **[Flutter](https://flutter.dev/):** Framework principal para desenvolvimento da interface e lógica do app.
- **[Geolocator](https://pub.dev/packages/geolocator):** Plugin para obter a localização (latitude e longitude) e calcular distâncias e direções (*bearing*).
- **[Audioplayers](https://pub.dev/packages/audioplayers):** Para reprodução do áudio de vitória ao alcançar o tesouro.
- **[Permission Handler](https://pub.dev/packages/permission_handler):** Gerenciamento de permissões do dispositivo.

---

##  Como Executar o Projeto

1. **Pré-requisitos:** Certifique-se de ter o [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado e configurado na sua máquina.
2. **Clone ou Baixe o Repositório.**
3. **Instale as dependências:**
   ```bash
   flutter pub get
   ```
4. **Permissões de GPS:** O app precisa de permissão de localização. Se estiver testando no Android, certifique-se de que o GPS do aparelho esteja ativado. (Em emuladores, você pode simular a localização alterando as coordenadas nas opções de rota).
5. **Execute o app:**
   ```bash
   flutter run
   ```

---

##  Objetivo Educacional
Este projeto foi desenvolvido como um **Exercício de Fixação e Aprofundamento** para explorar conceitos de hardware de dispositivos móveis, como o consumo do GPS, cálculos matemáticos para geolocalização e a criação de interfaces ricas, responsivas e animadas utilizando Flutter.
