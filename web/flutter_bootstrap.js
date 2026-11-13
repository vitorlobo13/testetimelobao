{{flutter_js}}
{{flutter_build_config}}

// O app roda dentro de #app (index.html), que começa abaixo da faixa do
// topo do iPhone. Assim a cor da faixa é o fundo da página, trocado na
// hora junto com o visual (Time Lobo / Time Lopes).
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      hostElement: document.querySelector('#app'),
    });
    await appRunner.runApp();
  },
});
