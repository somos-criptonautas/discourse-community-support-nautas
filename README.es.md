# Community Support

[![Discourse Theme](https://github.com/somos-criptonautas/discourse-community-support-nautas/actions/workflows/discourse-theme.yml/badge.svg)](https://github.com/somos-criptonautas/discourse-community-support-nautas/actions/workflows/discourse-theme.yml)

[ENGLISH](README.md) | **ESPAÑOL**

Componente de tema de Discourse, independiente de la pasarela de pago, para apoyo a la comunidad, donaciones y widgets de recaudación. El mismo sistema de presentación se reutiliza en modales, publicaciones, plugin outlets y ubicaciones HTML como Discourse Ads.

Normalmente las donaciones son enlaces salientes. Con [discourse-btcpay-subscriptions](https://github.com/somos-criptonautas/discourse-btcpay-subscriptions) instalado, un método puede cobrar dentro de Discourse — ver [Donaciones con BTCPay](#donaciones-con-btcpay). Todas las funciones de BTCPay vuelven al comportamiento anterior cuando el plugin no está, así que el componente funciona igual sin él.

## Requisitos

- Discourse 3.4+ — el componente usa componentes Glimmer `.gjs` y el esquema de objetos para los ajustes
- Opcional: [discourse-btcpay-subscriptions](https://github.com/somos-criptonautas/discourse-btcpay-subscriptions) para donaciones dentro del sitio y totales en vivo

## Instalación

Admin → Personalizar → Temas → Componentes → Instalar → Desde un repositorio git, y añade la URL del repositorio. Si el repositorio es privado, usa la URL SSH y añade la clave de despliegue que muestra Discourse a las *Deploy keys* del repositorio.

Instálalo como componente y añádelo a los temas que deban mostrarlo.

## Funciones

- Activador manual `#donate` — cualquier enlace con ese href abre el modal
- Control de visibilidad por miembros/anónimos, nivel de confianza, rutas y grupos excluidos
- Los grupos excluidos ocultan los widgets de outlet y los embeds genéricos, mientras que los bloques contextuales `[wrap=donate]` y el enlace `#donate` siguen disponibles
- Métodos de donación con logotipos, enlaces y valores copiables (IBAN, alias, dirección…)
- El campo de importe y el botón del método destacado van dentro de la propia caja de apoyo
- Donaciones BTCPay dentro del sitio, con un campo de importe en lugar del enlace saliente
- Donaciones con tarjeta mediante un Payment Link de Stripe, con el importe prerrellenado — sin claves secretas en el tema
- Traducciones por método usando la lista de idiomas de Discourse
- Destacados configurables en la cabecera, con traducción por elemento desde la misma lista
- Objetivo y barra de progreso, alimentados por un ajuste manual o por los totales en vivo de BTCPay
- Periodos de objetivo único, mensual y anual
- Avatares de colaboradores, desde una lista manual, desde grupos y desde donantes reales de BTCPay
- Diseños Classic, Minimal y Modern
- Vistas Full, Compact, Minimal, Progress y Sidebar
- Un bloque para el componente [Right Sidebar Blocks](https://github.com/discourse/discourse-right-sidebar-blocks) del equipo de Discourse
- Envoltorios en publicaciones con `[wrap=donate*]`
- Embed HTML genérico para Discourse Ads y otras ubicaciones que admitan HTML
- Renderizado configurable en plugin outlets mediante `renderInOutlet`
- Se adapta a su propio ancho mediante container queries, así que encaja en una barra lateral, una publicación o un modal; soporte de movimiento reducido
- Semántica de progreso accesible y controles de copia accesibles por teclado

## Métodos de donación

Los métodos se configuran en el ajuste de objetos `donation_methods`. Un método puede marcarse como `featured`, lo que coloca su campo de importe y su botón dentro de la caja de apoyo; el resto se listan debajo.

```yaml
donation_methods:
  - featured: true
    name: "PayPal"
    description: "Apoya a la comunidad con PayPal."
    button_text: "Apoyar con PayPal"
    url: "https://paypal.me/ejemplo"
  - name: "Transferencia"
    description: "Transferencia directa, sin comisiones."
    button_text: "Ver datos"
    copy_label: "IBAN"
    copy_value: "ES00 0000 0000 0000 0000 0000"
```

| Campo | Para qué sirve |
| --- | --- |
| `featured` | Usa este método para el campo de importe y el botón de la caja |
| `name`, `description`, `button_text` | Texto de la tarjeta (obligatorio) |
| `url` | URL de apoyo saliente, o el Payment Link de Stripe cuando `use_stripe` está activo. Se ignora cuando `use_btcpay` está activo |
| `use_btcpay` | Cobra la donación en el sitio mediante el plugin de BTCPay |
| `use_stripe` | Trata `url` como un Payment Link de Stripe y lo prerrellena con el importe introducido |
| `icon` | Logotipo del proveedor, opcional (subida) |
| `owner`, `provider` | Beneficiario y proveedor de pago opcionales, mostrados en la tarjeta |
| `copy_label`, `copy_value` | Valor copiable de un clic, como un IBAN o una dirección |
| `translations` | Traducción por idioma de los campos de texto |

## Donaciones con BTCPay

Activa `use_btcpay` en un método para cobrar la donación sin salir de Discourse:

```yaml
donation_methods:
  - name: "Bitcoin"
    description: "Dona con Bitcoin o Lightning."
    button_text: "Donar"
    use_btcpay: true
```

La tarjeta muestra entonces un campo de importe y un botón en lugar de un enlace. Al pulsar el botón:

1. se envía el importe a `POST /btcpay/donate.json`, y el plugin responde con un id de factura, una URL de modal y una URL de checkout alojado;
2. se carga el propio script modal de BTCPay y se llama a `window.btcpay.showInvoice()` con ese id de factura;
3. si el script no carga, se redirige a la página de checkout alojada.

El botón queda deshabilitado mientras se crea la factura y mientras la ventana está abierta, de modo que un doble clic no puede apilar dos ventanas. Los visitantes anónimos ven un botón de inicio de sesión, porque el endpoint solo atiende a usuarios identificados. Los errores de validación del plugin — un importe por debajo del mínimo, el límite de peticiones — se muestran bajo el campo.

El tema nunca habla directamente con BTCPay ni guarda ninguna clave de API. El id de pedido que atribuye una donación a un usuario de Discourse se genera en el servidor, así que el navegador no puede influir en él.

El mismo plugin alimenta dos piezas de solo lectura desde `GET /btcpay/donations.json`:

- el **total de la barra de apoyo**, que sustituye al ajuste manual `support_current` (`support_goal` sigue siendo manual);
- los **avatares de colaboradores**, combinados con la lista configurada a mano.

Ambas vuelven a sus ajustes manuales si la petición falla o el plugin no está. El endpoint se pide una sola vez por render de página y lo comparten todas las tarjetas, la barra y la lista de avatares.

El importe mínimo, la moneda de la donación y el límite de peticiones son ajustes del plugin, no de este componente.

**Qué métodos de pago ofrece BTCPay no se configura aquí.** La factura muestra lo que esté activado en tu *tienda* de BTCPay: BTC on-chain, Lightning, Monero, etc. BTCPay Server no procesa tarjetas por sí mismo; para tarjetas, añade un método de Stripe a su lado. Más abajo está la vía que las acredita.

## Donaciones con Stripe

Las donaciones con Stripe usan un [Payment Link](https://docs.stripe.com/payment-links), que no necesita clave secreta: la única forma de que Stripe viva en un componente de tema.

1. En el panel de Stripe, crea un Payment Link para un producto con **Los clientes eligen cuánto pagar**. Opcionalmente, fija un importe predefinido, un mínimo y un máximo.
2. Añade un método con ese enlace como `url` y `use_stripe` activado:

```yaml
donation_methods:
  - name: "Tarjeta"
    description: "Paga con tarjeta o cartera."
    button_text: "Donar con tarjeta"
    url: "https://buy.stripe.com/…"
    use_stripe: true
```

El método muestra el mismo campo de importe que BTCPay. Al enviarlo, abre el enlace en una pestaña nueva con:

- `prefilled_amount` — el importe en la unidad mínima de la moneda (10 EUR pasa a `1000`; las monedas sin decimales, como JPY, no se multiplican). La moneda sale de `support_currency`. El donante aún puede cambiar el importe en la página de Stripe, y Stripe aplica el mínimo y el máximo del propio enlace.
- `client_reference_id=discourse-<id de usuario>` para donantes identificados, de modo que las donaciones se puedan cruzar con cuentas del foro en el panel de Stripe. Se usa el id numérico porque Stripe descarta en silencio los valores fuera de `A-Z a-z 0-9 _ -`, y los nombres de usuario pueden llevar puntos.

En la página de Stripe se ofrecen tarjetas —y Apple Pay, Google Pay o Link si están activados en el enlace—. A diferencia de BTCPay, el formulario se muestra también a visitantes anónimos: Stripe no necesita cuenta en el foro.

Dos omisiones deliberadas. El correo del donante **no** se prerrellena, porque viajaría en la URL y acabaría en el historial del navegador y en los registros. Y las donaciones de Stripe **no** cuentan en la barra de apoyo: la referencia anterior la fija el navegador, lo que vale para una etiqueta en el panel de Stripe pero no para acreditar a nadie. Contarlas requeriría una pieza en el servidor que reciba el webhook `checkout.session.completed` de Stripe, igual que el plugin de BTCPay genera su id de pedido en el servidor.

Si un método tiene activados `use_btcpay` y `use_stripe` a la vez, gana BTCPay.

### Donaciones con tarjeta acreditadas, vía BTCPay

Si la tienda de BTCPay tiene el [plugin Stripe](https://plugin-builder.btcpayserver.org/public/plugins/stripe-payments) y el plugin de suscripciones de BTCPay tiene activado `btcpay_card_payments`, la donación con tarjeta de un miembro **identificado** no pasa por el Payment Link. El método `use_stripe` le pide al plugin una factura de donación con `payment_method: card`, y BTCPay la abre en su página de Stripe.

Es la misma factura y el mismo webhook que una donación en cripto, así que las donaciones con tarjeta cuentan en la barra de apoyo y en la lista de quienes apoyan, y otorgan la insignia de donante y los puntos. Eso resuelve la omisión de arriba. El importe se cobra en la `btcpay_donation_currency` del plugin, igual que con BTCPay.

Quien no tiene cuenta sigue recibiendo el Payment Link, porque el plugin solo puede atribuir una donación a una cuenta. Entonces la `url` del método es opcional: sin ella, los visitantes anónimos no ven opción de tarjeta.

## Disposición

La disposición por defecto es una caja, después la barra de progreso y después el resto de métodos:

```
┌─ caja de apoyo ────────────────────────────────────┐
│ ♥  Sostener nuestra comunidad                      │
│    Los proyectos financiados por    ┌───────┐      │
│    la comunidad dependen de…        │ 10 EUR│      │
│    [sin anuncios] [comunidad]       └───────┘      │
│                                     [   Donar   ]  │
│ ─────────────────────────────────────────────────  │
│ 120 EUR de 200 EUR · Mensual                  60%  │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
└────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────┐
│ ⬡  PayPal · paypal.me               [ Abrir PayPal]│
│    Apoya a la comunidad con PayPal.                │
├────────────────────────────────────────────────────┤
│ ⬡  Tarjeta · Stripe       [ 10 EUR ][Donar tarjeta]│
│    Paga con tarjeta o cartera.                     │
├────────────────────────────────────────────────────┤
│ ⬡  Transferencia · Caja Rural                      │
│    ┌ IBAN  ES00 0000 0000 0000  ⧉ ┐               │
└────────────────────────────────────────────────────┘
```

La caja es la cabecera y el método destacado en una sola pieza: el texto a la izquierda y el campo de importe y el botón de ese método a la derecha. Los demás métodos son filas de la lista inferior. Todas las filas comparten una misma plantilla —icono, texto, acción—, así que un método con beneficiario, proveedor o valor copiable queda alineado exactamente igual que uno sin ellos. Beneficiario y proveedor van en la línea del nombre; el valor copiable, en la columna de texto.

La disposición responde a su propio ancho y no al de la ventana (container queries). Por debajo de unos 36rem, la acción de la caja pasa bajo su texto y la de cada fila bajo el suyo, de modo que se lee bien en una columna lateral estrecha dentro de una pantalla ancha, donde los breakpoints de viewport seguirían diciendo «escritorio».

En las ubicaciones independientes, la caja, la barra y la lista son tres superficies redondeadas con los mismos bordes. En el modal quedan a ras, porque el modal ya recorta sus propias esquinas. El icono lo define `support_icon` y es el único icono de la disposición.

## Barra de apoyo

La barra de apoyo se activa globalmente y puede mostrarse de forma independiente en el modal, los embeds en publicaciones, los plugin outlets y los embeds genéricos. Admite disposición inline, apilada y compacta.

Las cifras se leen en una sola línea —total recaudado, contra qué se mide, el periodo y el porcentaje— para que nada quede separado a lo ancho de la barra. `support_label` se usa como nombre accesible de la barra, no como título visible.

Por debajo del primer objetivo usa `tertiary-low` como pista y `tertiary` como relleno; al 100% exacto — y en cada hito exacto de 200%, 300%… — pista y relleno usan `success`. Entre hitos la pista usa `success-low` y el ciclo actual usa `success` como relleno, mientras el porcentaje mostrado sigue indicando el total real (por ejemplo 125% o 220%).

## Avatares de colaboradores

La barra de apoyo puede mostrar un número configurable de avatares pequeños. Los colaboradores vienen de tres fuentes, combinadas en este orden, y en caso de nombre repetido gana la primera:

1. el ajuste manual `supporters` — un nombre de usuario de Discourse, más un importe opcional, con perfil y avatar resueltos en tiempo de ejecución;
2. los donantes reales que informa el plugin de BTCPay, si está instalado;
3. los miembros de los grupos indicados en `supporter_groups`, del más reciente al más antiguo.

Cuando hay más colaboradores que avatares visibles, un menú `+N` abre la lista completa. `show_supporter_amounts` añade los importes a esa lista.

## Embeds en publicaciones

Activa `enable_post_embed` y usa cualquiera de estos envoltorios en una publicación:

```markdown
[wrap=donate]
[/wrap]

[wrap=donate-compact]
[/wrap]

[wrap=donate-minimal]
[/wrap]

[wrap=donate-progress]
[/wrap]
```

El envoltorio elige la vista, mientras que el ajuste global `design` controla el diseño visual.

## Embed genérico

Usa el marcador de embed estable allí donde el componente pueda decorar HTML cocinado:

```html
<div data-donation-widget="support"></div>
```

El marcador puede sobrescribir la presentación global:

```html
<div
  data-donation-widget="support"
  data-view="compact"
  data-design="minimal"
></div>
```

El HTML se mantiene estable mientras el componente es dueño de todo el marcado y el CSS, lo que hace el embed adecuado para ubicaciones HTML de Discourse Ads. Crea un anuncio HTML con el marcador y colócalo en el outlet de Ads que quieras; el anuncio no necesita CSS propio de donaciones.

## Plugin outlets

Activa `outlet_enabled` e indica uno o más nombres de outlet en `outlet_locations`, separados por `|`. El componente renderiza mediante `api.renderInOutlet()`.

Los widgets de outlet y los embeds genéricos respetan `url_must_contain`, `display_on_homepage`, `show_for_members`, `show_for_anon`, `trust_level` y `excluded_groups`, y se vuelven a comprobar en cada navegación. Los embeds en publicaciones se saltan esas comprobaciones a propósito: un bloque `[wrap=donate]` lo colocó ahí quien escribió la publicación.

Ejemplos: `above-main-container`, `before-topic-list`, `after-topic-list`, `topic-list-bottom`, `below-site-header`, `main-outlet-bottom`, `before-main-outlet`. La disponibilidad exacta depende de la versión de Discourse y de los temas y componentes instalados.

La vista y el diseño del outlet se configuran de forma independiente de los valores globales.

## Barra lateral derecha

El componente [Right Sidebar Blocks](https://github.com/discourse/discourse-right-sidebar-blocks) del equipo de Discourse muestra una columna de bloques junto a las listas de temas. Este componente incluye uno para ella, `donate-sidebar-block`, que muestra la vista `sidebar`.

Instala Right Sidebar Blocks y añade el bloque a su ajuste `blocks`:

```json
[{ "name": "donate-sidebar-block" }]
```

Ordénalo allí junto a los demás bloques. Dónde aparece la columna lo decide Right Sidebar Blocks —su ajuste `show_in_routes`, solo en rutas de listas de temas y nunca en móvil—. Este componente solo añade quién puede verlo —`show_for_members`, `show_for_anon`, `trust_level`, `excluded_groups`—. Aquí no aplica `url_must_contain` ni `display_on_homepage`: la ruta la decide Right Sidebar Blocks, y comprobar ambas cosas ocultaba el bloque en páginas donde se había colocado. La barra de apoyo se muestra si `support_bar_in_outlets` está activo.

Right Sidebar Blocks busca los bloques por nombre a través del resolver, que toma el primer módulo cuya ruta termine en `components/<nombre>`. Por eso el nombre es largo y específico; mantenlo así.

## Vistas y diseños

El diseño controla el lenguaje visual:

- `classic` — tarjetas equilibradas, estilo comunidad
- `minimal` — presentación compacta y sobria
- `modern` — tipografía mayor, más jerarquía, tarjetas elevadas

La vista controla cuánto contenido se muestra:

- `full` — cabecera completa, método destacado y lista de métodos
- `compact` — menos adorno para ubicaciones estrechas
- `minimal` — presentación centrada en los métodos
- `progress` — solo objetivo y progreso
- `sidebar` — un bloque compacto hecho a propósito: icono, título corto, barra fina, campo de importe y botón. No es la caja completa reducida: prescinde del texto de cabecera y de la lista de métodos porque no caben. Lo usa el [bloque de la barra lateral derecha](#barra-lateral-derecha) y se puede elegir para cualquier outlet.

Diseño y vista son ortogonales a propósito: cualquier vista funciona con cualquier diseño.

## Iconos

`support_icon` define el único icono de la disposición: la caja, el bloque de la barra lateral y el icono de reserva cuando un método no tiene logotipo subido. Por defecto es `ph-dt-hand-heart`, que requiere el [componente de iconos Phosphor Duotone](https://github.com/somos-criptonautas/discourse-phosphor-duotone-icons-nautas) instalado; usa `heart` o cualquier otro icono del núcleo si no usas ese componente.

## Idiomas

El componente incluye inglés y español; el resto de idiomas recurre al inglés. Los nombres de los métodos, las descripciones, las etiquetas de botón y los destacados de la cabecera se traducen por elemento en sus propios ajustes, no en los archivos de idioma, para que los administradores traduzcan sus textos sin tocar código.

## Desarrollo

```bash
pnpm install
pnpm lint          # eslint, prettier, stylelint, ember-template-lint
pnpm lint:fix
```

Las pruebas están en `test/acceptance/` y se ejecutan contra una instancia real de Discourse en CI. Cada push a `main` o pull request lanza el workflow compartido de temas de [discourse/.github](https://github.com/discourse/.github), que pasa los linters, valida `locales/en.yml` y `.discourse-compatibility`, y ejecuta la suite de QUnit.

Para ejecutarlas en local hace falta un checkout de desarrollo de Discourse:

```bash
cd ruta/a/discourse
bin/rake "themes:install[/ruta/a/discourse-community-support-nautas]"
bin/rake "themes:qunit[name,Community Support]"
```

## Licencia

MIT. Consulta [LICENSE](LICENSE).

Texto de este README bajo [CC BY-NC-SA 4.0](CC-BY-NC-SA-4.0.txt).
