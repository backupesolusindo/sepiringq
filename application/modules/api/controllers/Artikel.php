<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Artikel extends REST_Controller
{

  public function __construct()
  {
    parent::__construct();
    $this->load->model("ModelAPI/GetAPI");
  }

  public function Artikel_post()
  {
    $data = array(
      'judul' => $this->post("judul"),
      'tanggal' => date("Y-m-d H:i:s"),
      'penulis' => $this->post("penulis"),
      'konten' => $this->post("konten"),

    );

    if ($this->db->get_where("artikel", array('judul' => $this->post("judul")))->num_rows() < 1) {
      if ($this->db->get_where("artikel", array('penulis' => $this->post("penulis")))->num_rows() < 1) {
        if ($this->db->insert('artikel', $data)) {
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

  public function getartikel_get()
  {
    // echo "Coba";
    $data = $this->db->get("artikel");
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
}
