<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class GetAPI extends CI_Model {

    private $base_url = 'https://isipiringku.esolusindo.com/api/Token/token';

    public function get_access_token() {
        $client = new Client();

        // Konfigurasi permintaan untuk mengambil token
        $request = $client->request('POST', $this->base_url, [
            'form_params' => [
                'grant_type' => 'client_credentials',
                'client_id' => 'PKL2023',
                'client_secret' => 'PKLSERU'
            ]
        ]);

        // Ambil respons JSON dari server
        $response = $request->getBody()->getContents();

        // Parsing respons JSON untuk mendapatkan token
        $data = json_decode($response, true);

        // Mengembalikan access token
        return $data['access_token'];
    }
}
