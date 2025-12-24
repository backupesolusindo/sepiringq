<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Makanan extends REST_Controller
{

  public function __construct()
  {
    parent::__construct();
    //$this->load->model("ModelAuth");
  }

  public function makanan_post()
  {
    $data = array(
      'kategori' => $this->post("kategori"),
      'bahan_makanan' => $this->post("bahan_makanan"),
      'kuantitas' => $this->post("kuantitas"),
      'besaran' => $this->post("besaran"),

    );

    if ($this->db->get_where("bahan_makanan", array('bahan_makanan' => $this->post("bahan_makanan")))->num_rows() < 1) {
      if ($this->db->get_where("bahan_makanan", array('besaran' => $this->post("besaran")))->num_rows() < 1) {
        if ($this->db->insert('bahan_makanan', $data)) {
          $message = array(
            'status' => 200,
            'message' => "konten berhasil ditambahkan"
          );
        } else {
          $message = array(
            'status' => 500,
            'message' => "INTERNAL_SERVER_ERROR"
          );
        }
      } else {
        $message = array(
          'status' => 502,
          'message' => "Penulis Sudah Digunakan"
        );
      }
    } else {
      $message = array(
        'status' => 501,
        'message' => "Judul Sudah Digunakan"
      );
    }
    $this->response(array('response' => $data, 'message' => $message));
  }

  public function makanan_get()
  {
    // echo "Coba";
    $data = $this->db->get("bahan_makanan");
    if ($data->num_rows() > 0) {
      $message = array(
        'status' => $this->config->item('http_response_ok'),
        'message' => "OK"
      );
      $data = $data->result();
    } else {
      $data = array();
      $message = array(
        'status' => $this->config->item('http_response_ok_no_content'),
        'message' => "NO_CONTENT"
      );
    }
    $this->response(array('response' => $data, 'message' => $message));
  }

  public function konsumsi_get()
  {
    $id_user = $this->input->get("id_user");
    $waktu = $this->input->get("waktu");

    $this->db->select('bahan_makanan.nama_makanan, bahan_makanan.besaran, konsumsi_detail.*, bahan_makanan.energi');
    $this->db->from('konsumsi');
    $this->db->join('konsumsi_detail', 'konsumsi_detail.id_konsumsi = konsumsi.idkonsumsi');
    $this->db->join('bahan_makanan', 'bahan_makanan.id_makanan = konsumsi_detail.id_makanan');
    
    $this->db->where('konsumsi.user_id_user', $id_user);
    $this->db->where('DATE(konsumsi.waktu)', $waktu);

    $data = $this->db->get();

    if ($data->num_rows() > 0) {
      $message = array(
        'status' => $this->config->item('http_response_ok'),
        'message' => $data
      );
      $data = $data->result();
    } else {
      $data = array();
      $message = array(
        'status' => $this->config->item('http_response_ok_no_content'),
        'message' => "NO_CONTENT"
      );
    }
    $this->response(array('response' => $data, 'message' => $message));
  }

  public function allKonsumsi_get()
  {
    $id_user = $this->input->get("id_user");

    $this->db->select('bahan_makanan.nama_makanan, bahan_makanan.besaran, konsumsi_detail.*, bahan_makanan.energi, konsumsi.waktu');
    $this->db->from('konsumsi');
    $this->db->join('konsumsi_detail', 'konsumsi_detail.id_konsumsi = konsumsi.idkonsumsi');
    $this->db->join('bahan_makanan', 'bahan_makanan.id_makanan = konsumsi_detail.id_makanan');
    
    $this->db->where('konsumsi.user_id_user', $id_user);

    $data = $this->db->get();

    if ($data->num_rows() > 0) {
      $message = array(
        'status' => $this->config->item('http_response_ok'),
        'message' => $data
      );
      $data = $data->result();
    } else {
      $data = array();
      $message = array(
        'status' => $this->config->item('http_response_ok_no_content'),
        'message' => "NO_CONTENT"
      );
    }
    $this->response(array('response' => $data, 'message' => $message));
  }

}
