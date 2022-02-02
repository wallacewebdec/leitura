<?php

require_once __DIR__ . '/ApiBase.php';
require_once __DIR__ . '/../providers/Curl.php';
require_once __DIR__ . '/../providers/Api.php';

/**
 * Class Banco
 */
class Banco extends ApiBase
{
    /**
     * $url
     *
     * @var string
     */
    private $url = 'http://site.com/api';

    /**
     * $rota
     *
     * @var string
     */
    private $rota = 'production';

    /**
     * $loginHub
     *
     * @var
     */
    private $loginHub;

    /**
     * $senhaHub
     *
     * @var
     */
    private $senhaHub;

    /**
     * $tokenHub
     *
     * @var
     */
    private $tokenHub;

    /**
     * Banco constructor.
     *
     * @param $credenciais
     */
    public function __construct($credenciais)
    {
        # Seta as credencias.
        $this->usuario      = $credenciais['usuario'];
        $this->senha        = $credenciais['senha'];

        # Busca o WebService
        $this->buscarWebService();

        # Busca o token.
        $this->buscarToken();

    }

    /**
     * Buscar Web Service
     */
    public function buscarWebService()
    {
        $webservice = SincronismoBancos::getWebService('HubConsig');

        if (isset($webservice['parametros'])) {

            $HubConsig = explode(';', $webservice['parametros']);

            $this->loginHub = $HubConsig[0];
            $this->senhaHub = $HubConsig[1];
            $this->rota     = $HubConsig[2];
            $this->url      = $webservice['url_integracao'];

        }

    }

    /**
     * Buscar Token
     */
    public function buscarToken()
    {
        $res = Curl::post($this->url. '/login', [
            'email'    => $this->loginHub,
            'password'       => $this->senhaHub
        ]);

        $arrRes = json_decode($res, true);

        $this->tokenHub = isset($arrRes['data']['token']) ? $arrRes['data']['token'] : null;

    }

    /**
     * consultarPropostaPorId
     *
     * @param $codProposta
     * @return mixed
     */
    public function consultarPropostaPorId($codProposta)
    {
        $params = [
            'id'            => $codProposta,
            'usuario'       => $this->usuario,
            'senha'         => $this->senha,
            'route'         => $this->rota
        ];

        $curl = curl_init();

        curl_setopt_array($curl, array(
            CURLOPT_URL => $this->url . '/banco/consultarPropostaPorId',
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_ENCODING => "",
            CURLOPT_MAXREDIRS => 10,
            CURLOPT_TIMEOUT => 30,
            CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
            CURLOPT_CUSTOMREQUEST => "POST",
            CURLOPT_POSTFIELDS => http_build_query($params),
            CURLOPT_HTTPHEADER => array(
                "accept: application/json",
                "authorization: Bearer {$this->tokenHub}",
                "content-Type: application/x-www-form-urlencoded",
            ),
        ));

        $response = curl_exec($curl);
        curl_close($curl);

        $arrRes = json_decode($response, true);

        if (!isset($arrRes['success']) || $arrRes['success'] == false)
            $this->error = 'Não foi possivel consultar a proposta '. $codProposta;
        else
            return $arrRes['data']['proposta'];

    }

}
