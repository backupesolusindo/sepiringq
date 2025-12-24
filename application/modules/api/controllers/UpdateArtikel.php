<?php
defined('BASEPATH') or exit('No direct script access allowed');

class UpdateArtikel extends REST_Controller
{

    public function __construct()
    {
        parent::__construct();
        $this->load->model("ModelAuth");
    }

    public function UpdateArtikel_post()
    {
        $id_artikel = $this->post("id_artikel");

        $data = array(
            'judul' => $this->post("judul"),
            'tanggal' => date("Y-m-d H:i:s"),
            'penulis' => $this->post("penulis"),
            'konten' => $this->post("konten"),
        );

        // Lakukan validasi data di sini jika diperlukan

        if ($this->db->get_where("artikel", array('id_artikel' => $id_artikel))->num_rows() > 0) {
            if ($this->db->update('artikel', $data, array('id_artikel' => $id_artikel))) {
                $message = array(
                    'status' => 200,
                    'message' => "Artikel berhasil diperbarui"
                );
            } else {
                $message = array(
                    'status' => 500,
                    'message' => "INTERNAL_SERVER_ERROR"
                );
            }
        } else {
            $message = array(
                'status' => 404,
                'message' => "Artikel tidak ditemukan"
            );
        }
        $this->response(array('response' => $data, 'message' => $message));
    }
} 