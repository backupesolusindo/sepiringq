<?php
defined('BASEPATH') or exit('No direct script access allowed');

class DetailKonsumsi extends REST_Controller
{
    public function __construct()
    {
        parent::__construct();
        $this->load->model("ModelAuth");
    }

    public function DetailKonsumsi_post()
    {
        // $makanan = $this->post("makanan");
        $iddetail_konsumsi = $this->post("iddetail_konsumsi");

        // Mengecek apakah "makanan" yang diberikan ada dalam detail_konsumsi
        $detail_konsumsi = $this->db
            ->join("jenis", "jenis.idjenis = detail_konsumsi.jenis_idjenis")
            ->join("konsumsi", "konsumsi.idkonsumsi = detail_konsumsi.konsumsi_idkonsumsi")
            ->get_where("detail_konsumsi", array('iddetail_konsumsi' => $iddetail_konsumsi));

        if ($detail_konsumsi->num_rows() > 0) {
            // Mengambil catatan terkait dari tabel jenis dan konsumsi
            $detail_konsumsi_data = $detail_konsumsi->row_array();
            // $jenis_id = $detail_konsumsi_data['idjenis'];
            // $konsumsi_id = $detail_konsumsi_data['idkonsumsi'];

            // $jenis = $this->db->get_where("jenis", array(' idjenis' => $jenis_id))->row_array();
            // $konsumsi = $this->db->get_where("konsumsi", array('idkonsumsi' => $konsumsi_id))->row_array();

            $message = array(
                'status' => 200,
                'message' => "OK"
            );
        } else {
            $message = array(
                'status' => 501,
                'message' => "Makanan Sudah Digunakan"
            );
            // $jenis = array();
            // $konsumsi = array();
        }

        $response_data = array(
            'detail_konsumsi' => $detail_konsumsi_data,
            // 'jenis' => $jenis,
            // 'konsumsi' => $konsumsi,
            'message' => $message
        );

        $this->response($response_data);
    }
}