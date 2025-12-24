<?php
defined('BASEPATH') or exit('No direct script access allowed');

class HitungKalori extends REST_Controller
{

    public function __construct()
    {
        parent::__construct();
        $this->load->model("ModelAuth");
    }

    public function HitungKalori_post()
    {
        $hitung_kalori = $this->db->get_where("hitung_kalori", array('nama_makanan' => $this->post("nama_makanan")));
        if ($hitung_kalori->num_rows() > 0) {
            $message = array(
                'status' => 200,
                'message' => "OK"
            );
        } else {
            $message = array(
                'status' => 501,
                'message' => "makanan Sudah Digunakan"
            );
        }
        $this->response(array('response' => $hitung_kalori->row_array(), 'message' => $message));
    }
}
