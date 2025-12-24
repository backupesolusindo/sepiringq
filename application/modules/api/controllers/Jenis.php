<?php
defined('BASEPATH') or exit('No direct script access allowed');

class Jenis extends REST_Controller
{

    public function __construct()
    {
        parent::__construct();
        $this->load->model("ModelAuth");
    }
    public function Jenis_get()
    {
        $idjenis = $this->input->get("idjenis");

        if ($idjenis !== null) {
            $jenis = $this->db->get_where("jenis", array('idjenis' => $idjenis));
        } else {
            $jenis = $this->db->get("jenis");
        }
        
        if ($jenis->num_rows() > 0) {
            $data = $jenis->result_array();
            $message = array(
                'status' => 200,
                'message' => "OK",
                'count'   => $jenis->num_rows(),
            );
        } else {
            $data = null;
            $message = array(
                'status' => 204,
                'message' => "NO_CONTENT"
            );
        }
        $this->response(array('response' => $data, 'message' => $message));
    }
}
