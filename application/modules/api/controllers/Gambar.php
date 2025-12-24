<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Gambar extends REST_Controller
{

  public function __construct()
  {
    parent::__construct();
    // $this->load->model("ModelAuth");
  }

  public function getgambar_get()
  {
    // echo "Coba";
    $data = $this->db->get("gambar");
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
